ItemModificationManager = {}

-- Called when a session is loaded to re-apply all saved modifications.
function ItemModificationManager:ReapplyAll()
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not modifiedEquipment or HLP.Count(modifiedEquipment) == 0 then return end

    for itemTemplateUUID, modifications in pairs(modifiedEquipment) do
        local template = Ext.Template.GetTemplate(itemTemplateUUID)
        if template and template.Stats then
            local stats = Ext.Stats.Get(template.Stats)
            if stats then
                local needsSync = false

                -- Re-apply passives
                if modifications.passives then
                    local passivesOnEquip = HLP.GetAttr(stats, "PassivesOnEquip") or ""
                    for passiveId, _ in pairs(modifications.passives) do
                        if not string.find(passivesOnEquip, passiveId, 1, true) then
                            passivesOnEquip = (passivesOnEquip == "" and passiveId) or (passivesOnEquip .. ";" .. passiveId)
                            needsSync = true
                        end
                    end
                    stats.PassivesOnEquip = passivesOnEquip
                end

                -- Re-apply statuses
                if modifications.statuses then
                    local statusOnEquip = HLP.GetAttr(stats, "StatusOnEquip") or ""
                    for statusId, _ in pairs(modifications.statuses) do
                        if not string.find(statusOnEquip, statusId, 1, true) then
                            statusOnEquip = (statusOnEquip == "" and statusId) or (statusOnEquip .. ";" .. statusId)
                            needsSync = true
                        end
                    end
                    stats.StatusOnEquip = statusOnEquip
                end
                
                if needsSync then
                    stats:Sync()
                end
            end
        end
    end
end

-- Subscribe to the session loaded event.
Ext.Events.SessionLoaded:Subscribe(function()
    ItemModificationManager:ReapplyAll()
end)

return ItemModificationManager