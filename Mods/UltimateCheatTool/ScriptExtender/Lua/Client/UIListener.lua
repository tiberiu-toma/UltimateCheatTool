SMS.SendEquipment:SetHandler(function (payload)
    if UI then
        local tab = UI.EquipmentTab

        tab:SetEquipment(payload)
    end
end)
SMS.SendNPCs:SetHandler(function (payload)
    if UI then
        local tab = UI.NPCTab
        tab:SetNPCs(payload)
    end
end)
SMS.SendSpells:SetHandler(function (payload)
    if UI then
        local tab = UI.SpellTab
        tab:SetSpells(payload)
    end
end)
SMS.SendPassives:SetHandler(function (payload)
    if UI then
        local tab = UI.PassiveTab
        tab:SetPassives(payload)
    end
end)
SMS.SendTags:SetHandler(function (payload)
    if UI then
        local tab = UI.TagTab
        tab:SetTags(payload)
    end
end)
SMS.SendStatuses:SetHandler(function (payload)
    if UI then
        local tab = UI.StatusTab

        tab:SetStatuses(payload)
    end
end)
SMS.SendConsumables:SetHandler(function (payload)
    if UI then
        local tab = UI.ConsumableTab
        tab:SetConsumables(payload)
    end
end)
SMS.SendWaypoints:SetHandler(function (payload)
    if UI then
        local Waypoints = payload.data
        
        local tab = UI.WaypointTab

        tab:SetWaypoints(Waypoints)
    end
end)

SMS.SendPartyMembers:SetHandler(function (payload)
    if UI and UI.CharSelector then
        local members = payload.data
        UI.CharSelector:SetPartyMembers(members)
    end
end)

SMS.SendModifiedItemsData:SetHandler(function(payload)
    if UI and UI.EquipmentSelector then
        local items = payload.data
        UI.EquipmentSelector:ShowModifiedItemsPopup(items)
    end
end)

SMS.SendEquippedItems:SetHandler(function(payload)
    if UI and UI.EquipmentSelector then
        local items = payload.data
        UI.EquipmentSelector:SetQuickPickItems(items)
    end
end)