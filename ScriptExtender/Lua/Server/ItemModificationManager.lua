ItemModificationManager = {}
local reapplyOnLoad = false

-- Called when a session is loaded to re-apply all saved modifications.
function ItemModificationManager:ReapplyAll()
	local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
	if not modifiedEquipment or HLP.Count(modifiedEquipment) == 0 then return end

	for itemInstanceUUID, modifications in pairs(modifiedEquipment) do
		local item = Ext.Entity.Get(itemInstanceUUID)
		if item then
			-- Re-apply damage boosts (direct boosts)
			if modifications.damage then
				for _, boostData in pairs(modifications.damage) do
					if boostData and boostData.boostString then
						Osi.AddBoosts(itemInstanceUUID, boostData.boostString, "", "")
					end
				end
			end

			-- Re-apply direct passive boosts
			if modifications.directPassives then
                for passiveId, _ in pairs(modifications.directPassives) do
                    Osi.AddPassive(itemInstanceUUID, passiveId)
                end
			end

			-- Re-apply direct statuses
			if modifications.directStatuses then
				for statusId, _ in pairs(modifications.directStatuses) do
					Osi.ApplyStatus(itemInstanceUUID, statusId, -1, 1)
				end
			end

			-- Re-apply passives and statuses (stats modification)
			if modifications.passives or modifications.statuses then
				local templateUUID = modifications.templateUUID
				if templateUUID then
					local originalStatsName = Ext.Template.GetTemplate(templateUUID).Stats
					local originalStats = Ext.Stats.Get(originalStatsName)
					if originalStats then
						local instanceStatsName = originalStatsName .. "_UCT_" .. itemInstanceUUID
						local instanceStats = Ext.Stats.Get(instanceStatsName)
						if not instanceStats then
							instanceStats = Ext.Stats.Create(instanceStatsName, originalStats.ModifierList, originalStatsName)
						end
						if instanceStats then
							local passivesToApply = {}
							if modifications.passives then
								for passiveId, _ in pairs(modifications.passives) do
									table.insert(passivesToApply, passiveId)
								end
							end
							instanceStats.PassivesOnEquip = table.concat(passivesToApply, ";")

							local statusesToApply = {}
							if modifications.statuses then
								for statusId, _ in pairs(modifications.statuses) do
									table.insert(statusesToApply, statusId)
								end
							end
							instanceStats.StatusOnEquip = table.concat(statusesToApply, ";")

							instanceStats:Sync()
							item.Data.StatsId = instanceStatsName
							item:Replicate("Data")
							HLP.RefreshEquippedItem(nil, templateUUID)
						end
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
        -- Tell the client to refresh its inventory after a delay to account for the re-equip ticks.
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Inventory" }, GetHostCharacter(), 20)
    end
end)

return ItemModificationManager