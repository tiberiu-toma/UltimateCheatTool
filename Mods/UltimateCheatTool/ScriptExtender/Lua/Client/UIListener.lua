SMS.SendEquipment:SetHandler(function (payload)
    if UI then
        local tab = UI.EquipmentTab

        tab:SetData(payload)
    end
end)
SMS.SendNPCs:SetHandler(function (payload)
    if UI then
        local tab = UI.NPCTab
        tab:SetData(payload)
    end
end)
SMS.SendSpells:SetHandler(function (payload)
    if UI then
        local tab = UI.SpellTab
        tab:SetData(payload)
    end
end)
SMS.SendPassives:SetHandler(function (payload)
    if UI then
        local tab = UI.PassiveTab
        tab:SetData(payload)
    end
end)
SMS.SendTags:SetHandler(function (payload)
    if UI then
        local tab = UI.TagTab
        tab:SetData(payload)
    end
end)
SMS.SendStatuses:SetHandler(function (payload)
    if UI then
        local tab = UI.StatusTab

        tab:SetData(payload)
    end
end)
SMS.SendConsumables:SetHandler(function (payload)
    if UI then
        local tab = UI.ConsumableTab
        tab:SetData(payload)
    end
end)
SMS.SendWaypoints:SetHandler(function (payload)
    if UI then
        local tab = UI.WaypointTab

        tab:SetData(payload)
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