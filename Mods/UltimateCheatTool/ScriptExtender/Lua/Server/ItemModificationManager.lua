ItemModificationManager = {}
local reapplyOnLoad = false

-- Resets all stats objects that have a _UCT_BACKUP to their original state.
-- This is called on session load to clean up any modifications from previous sessions,
-- ensuring that items no longer being modified revert to their vanilla stats.
function ItemModificationManager:ResetAllModifiedStats()
    local allStatNames = Ext.Stats.GetStats()
    if not allStatNames then return end

    for _, statName in ipairs(allStatNames) do
        -- We only care about original stats, not the backups themselves
        if not string.find(statName, "_UCT_BACKUP", 1, true) then
            local backupName = statName .. "_UCT_BACKUP"
            local backupStat = Ext.Stats.Get(backupName)

            if backupStat then
                local stat = Ext.Stats.Get(statName)
                if stat then
                    local needsSync = false
                    local backupPassives = HLP.GetAttr(backupStat, "PassivesOnEquip") or ""
                    local backupStatuses = HLP.GetAttr(backupStat, "StatusOnEquip") or ""

                    if (HLP.GetAttr(stat, "PassivesOnEquip") or "") ~= backupPassives then
                        stat.PassivesOnEquip = backupPassives
                        needsSync = true
                    end
                    if (HLP.GetAttr(stat, "StatusOnEquip") or "") ~= backupStatuses then
                        stat.StatusOnEquip = backupStatuses
                        needsSync = true
                    end

                    if needsSync then
                        stat:Sync()
                    end
                end
            end
        end
    end
end

-- Called when a session is loaded to re-apply all saved modifications.
function ItemModificationManager:ReapplyAll()
	-- First, reset any stats that were modified in a previous session.
    self:ResetAllModifiedStats()

	local allCharacters = HLP.GetAllChars()

    -- Refresh ALL currently equipped items for all characters.
    -- This ensures that any items whose stats were reset by ResetAllModifiedStats
    -- (even if they are not in modifiedEquipment) are properly updated to their vanilla state.
    for _, charUUID in ipairs(allCharacters) do
        local equippedItems = EKP.GetEquippedItems(charUUID) -- EKP.GetEquippedItems returns a list of item data tables
        for _, itemData in ipairs(equippedItems) do
            HLP.RefreshEquippedItem(charUUID, itemData.id)
        end
    end

	local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
	if not modifiedEquipment or HLP.Count(modifiedEquipment) == 0 then return end

	for itemTemplateUUID, modifications in pairs(modifiedEquipment) do
		local template = Ext.Template.GetTemplate(itemTemplateUUID)
		if template and template.Stats then
			local stats = Ext.Stats.Get(template.Stats)
			if stats then
				local needsSync = false
				
				-- Ensure a backup exists, creating it if it's the first time this item is modified.
				local backupStatsName = stats.Name .. "_UCT_BACKUP"
				if not Ext.Stats.Get(backupStatsName) then
					local modifierList = stats.ModifierList
					if modifierList == "Weapon" or modifierList == "Armor" then
						local backupStats = Ext.Stats.Create(backupStatsName, modifierList, stats.Name)
						if backupStats then backupStats:Sync() end
					end
				end

				-- Re-apply passives
				if modifications.passives then
					local passivesOnEquip = HLP.GetAttr(stats, "PassivesOnEquip") or ""
					for passiveId, _ in pairs(modifications.passives) do
						passivesOnEquip = (passivesOnEquip == "" and passiveId) or (passivesOnEquip .. ";" .. passiveId)
					end
					stats.PassivesOnEquip = passivesOnEquip
					needsSync = true
				end

				-- Re-apply statuses
				if modifications.statuses then
					local statusOnEquip = HLP.GetAttr(stats, "StatusOnEquip") or ""
					for statusId, _ in pairs(modifications.statuses) do
						statusOnEquip = (statusOnEquip == "" and statusId) or (statusOnEquip .. ";" .. statusId)
					end
					stats.StatusOnEquip = statusOnEquip
					needsSync = true
				end
				
				if needsSync then
					stats:Sync()
					-- Refresh the item for any character who has it equipped to apply the custom changes.
                    -- This is a second refresh for items in modifiedEquipment, but it's necessary
                    -- to apply the *specific* custom modifications after the global reset, and
                    -- HLP.RefreshEquippedItem is safe to call multiple times.
					for _, charUUID in ipairs(allCharacters) do
                        HLP.RefreshEquippedItem(charUUID, itemTemplateUUID)
                    end
				end
			end
		end
	end
end

-- Subscribe to the session loaded event.
Ext.Events.SessionLoaded:Subscribe(function()
    -- Set a flag that we need to re-apply stats, but don't do it yet.
    -- Calling Osi functions during SessionLoaded is a restricted context and will crash.
    reapplyOnLoad = true
end)

-- Wait for the game to enter a safe state before running the logic.
Ext.Events.GameStateChanged:Subscribe(function(ev)
    -- When the game is running and we have a pending re-apply, execute it.
    if reapplyOnLoad and ev.ToState == "Running" and GetHostCharacter() then
        reapplyOnLoad = false
        ItemModificationManager:ReapplyAll()
    end
end)

return ItemModificationManager