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

SMS.UIRefresh:SetHandler(function(payload)
    if not UI or not UI.Ready then return end

    -- Defer to next tick to be safe, as the variable might still be syncing.
    -- We subscribe to the UI Tick event and immediately unsubscribe to ensure this runs only once,
    -- after the current frame has processed.
    local tabName = payload.tab
    if tabName == "Passive" and UI.PassiveTab and UI.PassiveTab.Tab.Visible then
        UI.PassiveTab:GetAddedPassives()
    elseif tabName == "Status" and UI.StatusTab and UI.StatusTab.Tab.Visible then
        UI.StatusTab:GetAppliedStatuses()
    elseif tabName == "Spell" and UI.SpellTab and UI.SpellTab.Tab.Visible then
        UI.SpellTab:GetLearnedSpells()
    elseif tabName == "Tag" and UI.TagTab and UI.TagTab.Tab.Visible then
        UI.TagTab:GetAppliedTags()
    elseif tabName == "NPC" and UI.NPCTab and UI.NPCTab.Tab.Visible then
        UI.NPCTab:GetSpawnedNPCs()
    end
end)