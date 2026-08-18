local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class CharacterBuffsTab
---@field Tab ExtuiTabItem
---@field MainContent ExtuiGroup
---@field ModificationGrid ModificationGrid
CharacterBuffsTab = {}
setmetatable(CharacterBuffsTab, { __index = BaseTab })
CharacterBuffsTab.__index = CharacterBuffsTab

-- Data for buff options
local buffData = {
    Combat = {
        MaxHP = { name = "Max HP", boost = "IncreaseMaxHP", amounts = {1, 10, 100}, format = "+%d Max HP" },
        AC = { name = "Armor Class", boost = "AC", amounts = {1, 5, 10}, format = "+%d AC" },
        Initiative = { name = "Initiative", boost = "Initiative", amounts = {1, 5, 10}, format = "+%d Initiative" },
        AttackRolls = { name = "Attack Rolls", boost = "RollBonus(Attack,%d)", amounts = {1, 2, 5}, format = "+%d Attack Rolls" },
        SpellSaveDC = { name = "Spell Save DC", boost = "SpellSaveDC", amounts = {1, 2, 5}, format = "+%d Spell Save DC" },
        CritThreshold = { name = "Crit Threshold", boost = "ReduceCriticalAttackThreshold", amounts = {1, 2, 5}, format = "-%d Crit Threshold" },
    },
    Utility = {
        SkillChecks = { name = "Skill Checks", boost = "RollBonus(SkillCheck,%d)", amounts = {1, 2, 5}, format = "+%d Skill Checks" },
        CarryCapacity = { name = "Carry Capacity", boost = "CarryCapacityMultiplier", amounts = {10, 100, 1000}, format = "x%d Carry Capacity" },
    },
    Toggles = {
        Invulnerable = { name = "Invulnerable", boost = "Invulnerable()" },
        NoFallDamage = { name = "Ignore Fall Damage", boost = "FallDamageMultiplier(0.0)" },
    }
}

function CharacterBuffsTab:New(holder)
    local config = {
        tabName = "Buffs",
        tabNameHandle = "UCT_CharacterBuffsTab_Label",
        idPrefix = "CharacterBuffs"
    }
    local instance = BaseTab:New(holder, config)
    setmetatable(instance, CharacterBuffsTab)

    local gridConfig = {
        headerText = "Active Buffs",
        noItemsText = "No custom buffs applied.",
        maxTableWidth = 4,
        idPrefix = "CharacterBuffs",
        renderItem = function(cell, uuid, data)
            local button = cell:AddButton(data.displayName .. "##AppliedBuff" .. uuid)
            local popup = cell:AddPopup("ManageBuff" .. uuid)
            button.OnClick = function() popup:Open() end

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                SMS.ManageCharacterBuff:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    return instance
end

function CharacterBuffsTab:Init()
    self:Draw()
end

local function _CreateBuffButtons(parent, buffInfo)
    local row = parent:AddRow()
    row:AddCell():AddText(buffInfo.name .. ":")
    for _, amount in ipairs(buffInfo.amounts) do
        local btn = row:AddCell():AddButton(string.format(buffInfo.format, amount):gsub("%+", "+"):gsub("%%", "") .. "##" .. buffInfo.boost .. amount)
        btn.OnClick = function()
            local boostString
            if string.find(buffInfo.boost, "%%d") then
                boostString = string.format(buffInfo.boost, amount)
            else
                boostString = string.format("%s(%d)", buffInfo.boost, amount)
            end
            local displayName = string.format(buffInfo.format, amount)
            SMS.ManageCharacterBuff:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, boostString = boostString, displayName = displayName })
        end
    end
end

function CharacterBuffsTab:Draw()
    if self.MainContent then
        UI_Utils.DestroyChildren(self.MainContent)
    else
        self.MainContent = self.Tab:AddGroup("CharacterBuffsTabMainContent")
    end

    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        self.MainContent:AddText("Select a character to apply buffs.")
        return
    end

    local modGroup = self.MainContent:AddGroup("ModifyBuffs")

    -- Combat
    modGroup:AddSeparatorText("Combat Enhancements")
    local combatTable = modGroup:AddTable("CombatBuffsTable", 4)
    combatTable.SizingFixedFit = true
    for _, buffInfo in pairs(buffData.Combat) do
        _CreateBuffButtons(combatTable, buffInfo)
    end
    modGroup:AddSeparator()

    -- Utility
    modGroup:AddSeparatorText("Utility & Survival")
    local utilityTable = modGroup:AddTable("UtilityBuffsTable", 5)
    utilityTable.SizingFixedFit = true
    for _, buffInfo in pairs(buffData.Utility) do
        _CreateBuffButtons(utilityTable, buffInfo)
    end
    
    -- Toggles
    local toggleRow = utilityTable:AddRow()
    for _, buffInfo in pairs(buffData.Toggles) do
        local btn = toggleRow:AddCell():AddButton(buffInfo.name)
        btn.OnClick = function()
            SMS.ManageCharacterBuff:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, boostString = buffInfo.boost, displayName = buffInfo.name })
        end
    end
    modGroup:AddSeparator()

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local appliedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].characterBuffs) or {}

    if HLP.Count(appliedForChar) > 0 then
        local clearAllBtn = self.MainContent:AddButton("Clear All Buffs")
        clearAllBtn.OnClick = function()
            SMS.ClearAllCharacterBuffs:SendToServer({ ID = USERID, character = UIState.SelectedCharacter })
        end
    end

    self.ModificationGrid:Draw(appliedForChar)
end

return CharacterBuffsTab