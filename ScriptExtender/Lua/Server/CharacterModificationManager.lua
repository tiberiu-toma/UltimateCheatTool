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

-- Called when a session is loaded to re-apply all saved modifications.
function CharacterModificationManager:ReapplyAll()
	-- Re-apply boosts from CharacterModifications
	local modifiedCharacters = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications
	if modifiedCharacters and HLP.Count(modifiedCharacters) > 0 then
		for charUUID, modifications in pairs(modifiedCharacters) do
			-- Re-apply spells
			if modifications.spells and HLP.Count(modifications.spells) > 0 then
                -- Save the hotbar before we mess with the spells
                HotbarManager.Save(charUUID)

                local spellBoosts = {}
                for _, spellData in pairs(modifications.spells) do
                    if spellData.boostString then
                        table.insert(spellBoosts, spellData.boostString)
                    end
                end
                -- Remove all first to prevent issues, then re-add after a delay.
                if #spellBoosts > 0 then
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
                            -- Schedule the hotbar to be restored
                            HotbarManager.Restore(charUUID)
                            Ext.Events.Tick:Unsubscribe(e)
                        end
                    end)
                end
			end

			-- Re-apply resources
            -- Commented out as it is not necessary anymore, and it was causing a bug
            --ReapplyStackingBoosts(charUUID, modifications.resources)

			-- Re-apply abilities
            ReapplyStackingBoosts(charUUID, modifications.abilities)

			-- Re-apply skills
            ReapplyStackingBoosts(charUUID, modifications.skills)
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
    -- When the game is running and we have a pending re-apply, execute it.
    if reapplyOnLoad and ev.ToState == "Running" and GetHostCharacter() then
        reapplyOnLoad = false
        CharacterModificationManager:ReapplyAll()
    end

    -- After a long rest or loading a save, re-apply modifications that might have been cleared.
    if ev.FromState == "Save" and ev.ToState == "Running" then
        -- A small delay is needed to ensure all characters and the game world are fully loaded.
        local ticks = 0
        local e
        e = Ext.Events.Tick:Subscribe(function()
            ticks = ticks + 1
            if ticks >= 10 then -- Wait a few ticks
                CharacterModificationManager:ReapplyAll()
                Ext.Events.Tick:Unsubscribe(e)
            end
        end)
    end
end)

return CharacterModificationManager