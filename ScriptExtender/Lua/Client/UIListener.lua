--- Creates a generic handler for receiving paginated data and updating a tab.
---@param getTab function A function that returns the tab object.
---@return function
local function CreateDataHandler(getTab)
    return function(payload)
        local tab = getTab()
        if tab then
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
    if CharacterTools and CharacterTools.PassiveTab then
        CharacterTools.PassiveTab:SetData(payload)
    end
    if ItemTools and ItemTools.PassiveTab then
        ItemTools.PassiveTab:SetData(payload)
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
        if ItemTools and ItemTools.PassiveTab and ItemTools.PassiveTab.Tab.Visible then ItemTools.PassiveTab:GetAddedPassives() end
        if CharacterTools and CharacterTools.PassiveTab and CharacterTools.PassiveTab.Tab.Visible then CharacterTools.PassiveTab:GetAddedPassives() end
    end,
    Status = function()
        if ItemTools and ItemTools.StatusTab and ItemTools.StatusTab.Tab.Visible then ItemTools.StatusTab:GetAppliedStatuses() end
        if CharacterTools and CharacterTools.StatusTab and CharacterTools.StatusTab.Tab.Visible then CharacterTools.StatusTab:GetAppliedStatuses() end
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