SMS.SendEquipment:SetHandler(function (payload)
    if ItemTools then
        local tab = ItemTools.EquipmentTab

        tab:SetData(payload)
    end
end)
SMS.SendNPCs:SetHandler(function (payload)
    if CharacterTools then
        local tab = CharacterTools.NPCTab
        tab:SetData(payload)
    end
end)
SMS.SendSpells:SetHandler(function (payload)
    if CharacterTools then
        local tab = CharacterTools.SpellTab
        tab:SetData(payload)
    end
end)
SMS.SendPassives:SetHandler(function (payload)
    if CharacterTools and CharacterTools.PassiveTab then
        CharacterTools.PassiveTab:SetData(payload)
    end
    if ItemTools and ItemTools.PassiveTab then
        ItemTools.PassiveTab:SetData(payload)
    end
end)
SMS.SendTags:SetHandler(function (payload)
    if CharacterTools then
        local tab = CharacterTools.TagTab
        tab:SetData(payload)
    end
end)
SMS.SendStatuses:SetHandler(function (payload)
    if CharacterTools and CharacterTools.StatusTab then
        CharacterTools.StatusTab:SetData(payload)
    end
    if ItemTools and ItemTools.StatusTab then
        ItemTools.StatusTab:SetData(payload)
    end
end)
SMS.SendConsumables:SetHandler(function (payload)
    if ItemTools then
        local tab = ItemTools.ConsumableTab
        tab:SetData(payload)
    end
end)
SMS.SendWaypoints:SetHandler(function (payload)
    if CharacterTools then
        local tab = CharacterTools.WaypointTab

        tab:SetData(payload)
    end
end)

SMS.SendPartyMembers:SetHandler(function (payload)
    if CharacterTools and CharacterTools.CharSelector then
        local members = payload.data
        CharacterTools.CharSelector:SetPartyMembers(members)
    end
end)

SMS.SendModifiedItemsData:SetHandler(function(payload)
    if ItemTools and ItemTools.EquipmentSelector then
        local items = payload.data
        ItemTools.EquipmentSelector:ShowModifiedItemsPopup(items)
    end
end)

SMS.SendEquippedItems:SetHandler(function(payload)
    if ItemTools and ItemTools.EquipmentSelector then
        -- payload contains { party = {members...}, items = { [charUUID] = {items...} } }
        ItemTools.PartyMembers = payload.party or {}
        ItemTools.EquipmentSelector:UpdatePartyEquipment(payload.items or {})
    end
end)

SMS.UIRefresh:SetHandler(function(payload)
    if not CharacterTools and not ItemTools then return end
    local tabName = payload.tab
    if tabName == "Passive" then
        if ItemTools and ItemTools.PassiveTab and ItemTools.PassiveTab.Tab.Visible then
            ItemTools.PassiveTab:GetAddedPassives()
        end
        if CharacterTools and CharacterTools.PassiveTab and CharacterTools.PassiveTab.Tab.Visible then
            CharacterTools.PassiveTab:GetAddedPassives()
        end
    end
    if tabName == "Status" then
        if ItemTools and ItemTools.StatusTab and ItemTools.StatusTab.Tab.Visible then
            ItemTools.StatusTab:GetAppliedStatuses()
        end
        if CharacterTools and CharacterTools.StatusTab and CharacterTools.StatusTab.Tab.Visible then
            CharacterTools.StatusTab:GetAppliedStatuses()
        end
    end
    if tabName == "Spell" and CharacterTools and CharacterTools.SpellTab and CharacterTools.SpellTab.Tab.Visible then
        CharacterTools.SpellTab:GetLearnedSpells()
    end
    if tabName == "Tag" and CharacterTools and CharacterTools.TagTab and CharacterTools.TagTab.Tab.Visible then
        CharacterTools.TagTab:GetAppliedTags()
    end
    if tabName == "NPC" and CharacterTools and CharacterTools.NPCTab and CharacterTools.NPCTab.Tab.Visible then
        CharacterTools.NPCTab:GetSpawnedNPCs()
    end
end)