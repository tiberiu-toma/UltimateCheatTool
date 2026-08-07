CharacterModificationManager = {}
local reapplyOnLoad = false

-- Called when a session is loaded to re-apply all saved modifications.
function CharacterModificationManager:ReapplyAll()
	local modifiedCharacters = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
	if not modifiedCharacters or HLP.Count(modifiedCharacters) == 0 then return end

	for charUUID, modifications in pairs(modifiedCharacters) do
		-- Re-apply spells
		if modifications.spells then
			for spellId, spellData in pairs(modifications.spells) do
				if spellData.spellName and spellData.learningStrategy and spellData.castingAbility then
					local boostString = string.format("UnlockSpell(%s,%s,%s,,%s)", spellData.spellName, spellData.learningStrategy, "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", spellData.castingAbility)
					Osi.AddBoosts(charUUID, boostString, "", "")
				end
			end
		end

		-- Re-apply resources
		if modifications.resources then
			for boostKey, resourceModData in pairs(modifications.resources) do
				if resourceModData.boostString then
					Osi.AddBoosts(charUUID, resourceModData.boostString, "", "")
				end
			end
		end

		-- Re-apply abilities
		if modifications.abilities then
			for boostKey, abilityModData in pairs(modifications.abilities) do
				if abilityModData.boostString then
					Osi.AddBoosts(charUUID, abilityModData.boostString, "", "")
				end
			end
		end

		-- Re-apply skills
		if modifications.skills then
			for boostKey, skillModData in pairs(modifications.skills) do
				if skillModData.boostString then
					Osi.AddBoosts(charUUID, skillModData.boostString, "", "")
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
end)

return CharacterModificationManager