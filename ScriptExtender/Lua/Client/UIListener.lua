--- Creates a generic handler for receiving paginated data and updating a tab.
---@param getTab function A function that returns the tab object.
---@return function
local function CreateDataHandler(getTab)
    return function(payload)
        local tab = getTab()
        if tab and payload.tabInstanceId == tab.InstanceId then
            tab:SetData(payload)
        end
    end
end

SMS.SendEquipment:SetHandler(CreateDataHandler(function() return ItemTools and ItemTools.EquipmentTab end))
SMS.SendNPCs:SetHandler(CreateDataHandler(function() return MiscTools and MiscTools.NPCTab end))
SMS.SendSpells:SetHandler(CreateDataHandler(function() return CharacterTools and CharacterTools.SpellTab end))
SMS.SendTags:SetHandler(CreateDataHandler(function() return CharacterTools and CharacterTools.TagTab end))
SMS.SendResources:SetHandler(CreateDataHandler(function() return CharacterTools and CharacterTools.ResourceTab end))
SMS.SendConsumables:SetHandler(CreateDataHandler(function() return ItemTools and ItemTools.ConsumableTab end))
SMS.SendWaypoints:SetHandler(CreateDataHandler(function() return MiscTools and MiscTools.WaypointTab end))

-- Handlers for tabs that exist in multiple UI contexts
SMS.SendPassives:SetHandler(function (payload)
    if CharacterTools and CharacterTools.PassiveTab and payload.tabInstanceId == CharacterTools.PassiveTab.InstanceId then
        CharacterTools.PassiveTab:SetData(payload)
    end
    if ItemTools and ItemTools.PassiveTab and payload.tabInstanceId == ItemTools.PassiveTab.InstanceId then
        ItemTools.PassiveTab:SetData(payload)
    end
end)
SMS.SendStatuses:SetHandler(function (payload)
    if CharacterTools and CharacterTools.StatusTab and payload.tabInstanceId == CharacterTools.StatusTab.InstanceId then
        CharacterTools.StatusTab:SetData(payload)
    end
    if ItemTools and ItemTools.StatusTab and payload.tabInstanceId == ItemTools.StatusTab.InstanceId then
        ItemTools.StatusTab:SetData(payload)
    end
end)

SMS.SendEquipmentModNames:SetHandler(function (payload)
    if ItemTools and ItemTools.EquipmentTab and ItemTools.EquipmentTab.FilterComponent then
        ItemTools.EquipmentTab.FilterComponent:SetModNameOptions(payload.data)
    end
end)

SMS.SendSpellModNames:SetHandler(function (payload)
    if CharacterTools and CharacterTools.SpellTab and CharacterTools.SpellTab.FilterComponent then
        CharacterTools.SpellTab.FilterComponent:SetModNameOptions(payload.data)
    end
end)

SMS.SendPassiveModNames:SetHandler(function (payload)
    if CharacterTools and CharacterTools.PassiveTab and CharacterTools.PassiveTab.FilterComponent then
        CharacterTools.PassiveTab.FilterComponent:SetModNameOptions(payload.data)
    end
    if ItemTools and ItemTools.PassiveTab and ItemTools.PassiveTab.FilterComponent then
        ItemTools.PassiveTab.FilterComponent:SetModNameOptions(payload.data)
    end
end)

SMS.SendStatusModNames:SetHandler(function (payload)
    if CharacterTools and CharacterTools.StatusTab and CharacterTools.StatusTab.FilterComponent then
        CharacterTools.StatusTab.FilterComponent:SetModNameOptions(payload.data)
    end
    if ItemTools and ItemTools.StatusTab and ItemTools.StatusTab.FilterComponent then
        ItemTools.StatusTab.FilterComponent:SetModNameOptions(payload.data)
    end
end)

SMS.SendConsumableModNames:SetHandler(function (payload)
    if ItemTools and ItemTools.ConsumableTab and ItemTools.ConsumableTab.FilterComponent then
        ItemTools.ConsumableTab.FilterComponent:SetModNameOptions(payload.data)
    end
end)

SMS.SendAbilities:SetHandler(function(payload)
    if CharacterTools and CharacterTools.AbilityTab then
        CharacterTools.AbilityTab:UpdateAbilityScores(payload)
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

local refreshHandlers = {
    Passive = function()
        if ItemTools and ItemTools.PassiveTab and ItemTools.PassiveTab.Tab.Visible then
            ItemTools.PassiveTab:GetAppliedModifications()
            -- The unequip/re-equip on the server can change item stats, so refresh the quick pick dropdown
            ItemTools.EquipmentSelector:FetchEquippedItems()
        end
        if CharacterTools and CharacterTools.PassiveTab and CharacterTools.PassiveTab.Tab.Visible then CharacterTools.PassiveTab:GetAppliedModifications() end
    end,
    Status = function()
        if ItemTools and ItemTools.StatusTab and ItemTools.StatusTab.Tab.Visible then
            ItemTools.StatusTab:GetAppliedModifications()
            -- The unequip/re-equip on the server can change item stats, so refresh the quick pick dropdown
            ItemTools.EquipmentSelector:FetchEquippedItems()
        end
        if CharacterTools and CharacterTools.StatusTab and CharacterTools.StatusTab.Tab.Visible then CharacterTools.StatusTab:GetAppliedModifications() end
    end,
    Spell = function()
        if CharacterTools and CharacterTools.SpellTab and CharacterTools.SpellTab.Tab.Visible then CharacterTools.SpellTab:GetLearnedSpells() end
    end,
    Tag = function()
        if CharacterTools and CharacterTools.TagTab and CharacterTools.TagTab.Tab.Visible then CharacterTools.TagTab:GetAppliedTags() end
    end,
    Resource = function()
        if CharacterTools and CharacterTools.ResourceTab and CharacterTools.ResourceTab.Tab.Visible then CharacterTools.ResourceTab:GetAddedResources() end
    end,
    Ability = function()
        if CharacterTools and CharacterTools.AbilityTab and CharacterTools.AbilityTab.Tab.Visible then CharacterTools.AbilityTab:FetchAbilities(true) end
    end,
    Skill = function()
        if CharacterTools and CharacterTools.SkillsTab and CharacterTools.SkillsTab.Tab.Visible then CharacterTools.SkillsTab:Draw() end
    end,
    Proficiency = function()
        if CharacterTools and CharacterTools.ProficiencyTab and CharacterTools.ProficiencyTab.Tab.Visible then CharacterTools.ProficiencyTab:Draw() end
    end,
    Damage = function()
        if ItemTools and ItemTools.DamageTab and ItemTools.DamageTab.Tab.Visible then ItemTools.DamageTab:GetAddedDamage() end
    end,
    Inventory = function()
        if ItemTools and ItemTools.EquipmentSelector then
            ItemTools.EquipmentSelector:FetchEquippedItems()
        end
    end,
    NPC = function()
        if MiscTools and MiscTools.NPCTab and MiscTools.NPCTab.Tab.Visible then MiscTools.NPCTab:GetSpawnedNPCs() end
    end,
}

SMS.UIRefresh:SetHandler(function(payload)
    if not CharacterTools and not ItemTools then return end
    local tabName = payload.tab
    if refreshHandlers[tabName] then
        refreshHandlers[tabName]()
    end
end)