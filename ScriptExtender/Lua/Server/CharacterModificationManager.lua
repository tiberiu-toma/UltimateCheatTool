CharacterModificationManager = {}
local reapplyOnLoad = false

--- Re-applies boosts that can be stacked (e.g. ability/skill boosts).
--- It first removes all instances to prevent infinite stacking on load, then re-applies them.
---@param charUUID string The character to apply boosts to.
---@param boostMods table The table of modifications for a specific boost type.
local function ReapplyStackingBoosts(charUUID, boostMods)
    if not boostMods or HLP.Count(boostMods) == 0 then return end

    local boostsToApply = {}
    -- Count how many of each boost string we need to apply
    for _, modData in pairs(boostMods) do
        if modData and modData.boostString then
            boostsToApply[modData.boostString] = (boostsToApply[modData.boostString] or 0) + 1
        end
    end

    if HLP.Count(boostsToApply) == 0 then return end

    -- Remove all instances of these boosts first
    for boostString, _ in pairs(boostsToApply) do
        Osi.RemoveBoosts(charUUID, boostString, 99, "", "") -- Remove all
    end

    -- After a short delay, re-apply all boosts to avoid timing issues on load.
    local ticks = 0
    local e
    e = Ext.Events.Tick:Subscribe(function()
        ticks = ticks + 1
        if ticks >= 5 then -- Wait a few ticks
            for boostString, count in pairs(boostsToApply) do
                for i = 1, count do
                    Osi.AddBoosts(charUUID, boostString, "", "")
                end
            end
            Ext.Events.Tick:Unsubscribe(e)
        end
    end)
end

--- Snapshots the current resource amounts for all characters with resource modifications.
--- This is called right before a save so we can restore spent resource states on load.
local function SaveResourceSnapshots()
    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local snapshots = {}

    for charUUID, modifications in pairs(mods) do
        if modifications.resources and HLP.Count(modifications.resources) > 0 then
            local entity = Ext.Entity.Get(charUUID)
            if entity and entity.ActionResources and entity.ActionResources.Resources then
                snapshots[charUUID] = {}
                local seen = {}
                for _, modData in pairs(modifications.resources) do
                    if modData and modData.id then
                        local key = tostring(modData.id) .. ":" .. tostring(modData.level or 0)
                        if not seen[key] then
                            seen[key] = true
                            -- Iterate all resource entries to find the matching one by UUID and level
                            for _, entries in pairs(entity.ActionResources.Resources) do
                                for _, entry in pairs(entries) do
                                    if tostring(entry.ResourceUUID) == tostring(modData.id) and entry.Level == (modData.level or 0) then
                                        snapshots[charUUID][key] = entry.Amount
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).ResourceAmountSnapshots = snapshots
end

--- Re-applies resource boosts while preserving spent resource amounts.
--- After removing and re-adding boosts (which refills current amounts to max),
--- this function uses saved snapshots to restore the correct current amounts.
---@param charUUID string The character to apply boosts to.
---@param resourceMods table The table of resource modifications for the character.
local function ReapplyResourceBoosts(charUUID, resourceMods)
    if not resourceMods or HLP.Count(resourceMods) == 0 then return end

    local boostsToApply = {}
    local resourceInfo = {} -- Maps "uuid:level" -> { id, name, level }

    for _, modData in pairs(resourceMods) do
        if modData and modData.boostString then
            boostsToApply[modData.boostString] = (boostsToApply[modData.boostString] or 0) + 1
            local key = tostring(modData.id) .. ":" .. tostring(modData.level or 0)
            if not resourceInfo[key] then
                resourceInfo[key] = { id = modData.id, name = modData.name, level = modData.level or 0 }
            end
        end
    end

    if HLP.Count(boostsToApply) == 0 then return end

    -- Remove all instances of these boosts first
    for boostString, _ in pairs(boostsToApply) do
        Osi.RemoveBoosts(charUUID, boostString, 99, "", "")
    end

    -- After a short delay, re-apply all boosts then correct current amounts.
    local ticks = 0
    local e
    e = Ext.Events.Tick:Subscribe(function()
        ticks = ticks + 1
        if ticks >= 5 then
            -- Re-add all boosts (this will refill current amounts to max)
            for boostString, count in pairs(boostsToApply) do
                for i = 1, count do
                    Osi.AddBoosts(charUUID, boostString, "", "")
                end
            end
            Ext.Events.Tick:Unsubscribe(e)

            -- After another short delay, correct current amounts using saved snapshots
            local ticks2 = 0
            local e2
            e2 = Ext.Events.Tick:Subscribe(function()
                ticks2 = ticks2 + 1
                if ticks2 >= 3 then
                    local snapshots = Ext.Vars.GetModVariables(ModuleUUID).ResourceAmountSnapshots or {}
                    local charSnapshots = snapshots[charUUID]
                    if charSnapshots then
                        local entity = Ext.Entity.Get(charUUID)
                        if entity and entity.ActionResources and entity.ActionResources.Resources then
                            local changed = false
                            for key, savedAmount in pairs(charSnapshots) do
                                local info = resourceInfo[key]
                                if info then
                                    for _, entries in pairs(entity.ActionResources.Resources) do
                                        for _, entry in pairs(entries) do
                                            if tostring(entry.ResourceUUID) == tostring(info.id) and entry.Level == info.level then
                                                if entry.Amount > savedAmount then
                                                    entry.Amount = savedAmount
                                                    changed = true
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            if changed then
                                entity:Replicate("ActionResources")
                            end
                        end
                    end
                    Ext.Events.Tick:Unsubscribe(e2)
                end
            end)
        end
    end)
end

--- Re-applies spell boosts and handles hotbar restoration.
---@param charUUID string The character to apply boosts to.
---@param spellMods table The spell modification table for the character.
local function ReapplySpellBoosts(charUUID, spellMods)
    if not spellMods or HLP.Count(spellMods) == 0 then return end

    local spellBoosts = {}
    for _, data in pairs(spellMods) do
        if data.boostString then table.insert(spellBoosts, data.boostString) end
    end

    if #spellBoosts > 0 then
        HotbarManager.Save(charUUID)

        for _, boostString in ipairs(spellBoosts) do
            Osi.RemoveBoosts(charUUID, boostString, 1, "", "")
        end

        local ticks = 0
        local e
        e = Ext.Events.Tick:Subscribe(function()
            ticks = ticks + 1
            if ticks >= 5 then -- Wait a few ticks
                for _, boostString in ipairs(spellBoosts) do
                    Osi.AddBoosts(charUUID, boostString, "", "")
                end
                HotbarManager.Restore(charUUID)
                Ext.Events.Tick:Unsubscribe(e)
            end
        end)
    end
end

-- Called when a session is loaded to re-apply all saved modifications.
function CharacterModificationManager:ReapplyAll(isSave)
	-- Re-apply boosts from CharacterModifications
	local modifiedCharacters = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications
	if modifiedCharacters and HLP.Count(modifiedCharacters) > 0 then
		for charUUID, modifications in pairs(modifiedCharacters) do
			-- Re-apply spells (hotbar items)
			ReapplySpellBoosts(charUUID, modifications.spells)

			-- Re-apply reactions
            ReapplyStackingBoosts(charUUID, modifications.reactions)

			-- Re-apply abilities
            ReapplyStackingBoosts(charUUID, modifications.abilities)

			-- Re-apply skills
            ReapplyStackingBoosts(charUUID, modifications.skills)

			-- Re-apply proficiencies
            ReapplyStackingBoosts(charUUID, modifications.proficiencies)

			-- Re-apply resistances
            ReapplyStackingBoosts(charUUID, modifications.resistances)

			-- Re-apply character buffs
            ReapplyStackingBoosts(charUUID, modifications.characterBuffs)

			-- Re-apply resources (with spent amount preservation)
            if not isSave then
                ReapplyResourceBoosts(charUUID, modifications.resources)
            end
		end
	end

	-- Re-apply statuses from AppliedStatuses, which are often cleared on load/long rest.
	local appliedStatuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
	if appliedStatuses and HLP.Count(appliedStatuses) > 0 then
		for charUUID, statuses in pairs(appliedStatuses) do
			if Ext.Entity.Get(charUUID) then -- Check if character exists
				for statusId, _ in pairs(statuses) do
					-- Remove first to prevent stacking, then re-apply with infinite duration.
					Osi.RemoveStatus(charUUID, statusId)
					Osi.ApplyStatus(charUUID, statusId, -1, 1)
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
    -- When transitioning to Save, snapshot current resource amounts so we can
    -- restore spent resources after the boosts are re-applied on load.
    if ev.ToState == "Save" then
        SaveResourceSnapshots()
    end

    -- When the game is running and we have a pending re-apply, execute it.
    if reapplyOnLoad and ev.ToState == "Running" and GetHostCharacter() then
        reapplyOnLoad = false
        CharacterModificationManager:ReapplyAll(false)
    end

    -- After a long rest or loading a save, re-apply modifications that might have been cleared.
    if ev.FromState == "Save" and ev.ToState == "Running" then
        -- A small delay is needed to ensure all characters and the game world are fully loaded.
        local ticks = 0
        local e
        e = Ext.Events.Tick:Subscribe(function()
            ticks = ticks + 1
            if ticks >= 10 then -- Wait a few ticks
                CharacterModificationManager:ReapplyAll(true)
                Ext.Events.Tick:Unsubscribe(e)
            end
        end)
    end
end)

return CharacterModificationManager