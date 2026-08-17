local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class ProficiencyTab
---@field Tab ExtuiTabItem
---@field MainContent ExtuiGroup
---@field ModificationGrid ModificationGrid
ProficiencyTab = {}
setmetatable(ProficiencyTab, { __index = BaseTab })
ProficiencyTab.__index = ProficiencyTab

-- Data for proficiency options
local proficiencyData = {
    Armor = {
        { name = "Light Armor", boost = "Proficiency(LightArmor)" },
        { name = "Medium Armor", boost = "Proficiency(MediumArmor)" },
        { name = "Heavy Armor", boost = "Proficiency(HeavyArmor)" },
        { name = "Shields", boost = "Proficiency(Shields)" },
    },
    Weapons = {
        { name = "Simple Weapons", boost = "Proficiency(SimpleWeapons)" },
        { name = "Martial Weapons", boost = "Proficiency(MartialWeapons)" },
        { name = "Battleaxes", boost = "Proficiency(Battleaxes)" },
        { name = "Clubs", boost = "Proficiency(Clubs)" },
        { name = "Daggers", boost = "Proficiency(Daggers)" },
        { name = "Flails", boost = "Proficiency(Flails)" },
        { name = "Glaives", boost = "Proficiency(Glaives)" },
        { name = "Greataxes", boost = "Proficiency(Greataxes)" },
        { name = "Greatclubs", boost = "Proficiency(Greatclubs)" },
        { name = "Greatswords", boost = "Proficiency(Greatswords)" },
        { name = "Halberds", boost = "Proficiency(Halberds)" },
        { name = "Handaxes", boost = "Proficiency(Handaxes)" },
        { name = "Hand Crossbows", boost = "Proficiency(HandCrossbows)" },
        { name = "Heavy Crossbows", boost = "Proficiency(HeavyCrossbows)" },
        { name = "Javelins", boost = "Proficiency(Javelins)" },
        { name = "Light Crossbows", boost = "Proficiency(LightCrossbows)" },
        { name = "Light Hammers", boost = "Proficiency(LightHammers)" },
        { name = "Longbows", boost = "Proficiency(Longbows)" },
        { name = "Longswords", boost = "Proficiency(Longswords)" },
        { name = "Maces", boost = "Proficiency(Maces)" },
        { name = "Mauls", boost = "Proficiency(Mauls)" },
        { name = "Morningstars", boost = "Proficiency(Morningstars)" },
        { name = "Pikes", boost = "Proficiency(Pikes)" },
        { name = "Quarterstaffs", boost = "Proficiency(Quarterstaffs)" },
        { name = "Rapiers", boost = "Proficiency(Rapiers)" },
        { name = "Scimitars", boost = "Proficiency(Scimitars)" },
        { name = "Shortbows", boost = "Proficiency(Shortbows)" },
        { name = "Shortswords", boost = "Proficiency(Shortswords)" },
        { name = "Sickles", boost = "Proficiency(Sickles)" },
        { name = "Spears", boost = "Proficiency(Spears)" },
        { name = "Tridents", boost = "Proficiency(Tridents)" },
        { name = "Warhammers", boost = "Proficiency(Warhammers)" },
        { name = "War Picks", boost = "Proficiency(Warpicks)" },
    },
    SavingThrows = {
        { name = "Strength", boost = "ProficiencyBonus(SavingThrow,Strength)" },
        { name = "Dexterity", boost = "ProficiencyBonus(SavingThrow,Dexterity)" },
        { name = "Constitution", boost = "ProficiencyBonus(SavingThrow,Constitution)" },
        { name = "Intelligence", boost = "ProficiencyBonus(SavingThrow,Intelligence)" },
        { name = "Wisdom", boost = "ProficiencyBonus(SavingThrow,Wisdom)" },
        { name = "Charisma", boost = "ProficiencyBonus(SavingThrow,Charisma)" },
    },
    Skills = {
        "Acrobatics", "AnimalHandling", "Arcana", "Athletics", "Deception", "History",
        "Insight", "Intimidation", "Investigation", "Medicine", "Nature", "Perception",
        "Performance", "Persuasion", "Religion", "SleightOfHand", "Stealth", "Survival"
    },
    Instruments = {
        { name = "Musical Instrument", boost = "Proficiency(MusicalInstrument)" },
    }
}

function ProficiencyTab:New(holder)
    local config = {
        tabName = "Proficiency",
        tabNameHandle = "UCT_ProficiencyTab_Label",
        idPrefix = "Proficiency"
    }
    local instance = BaseTab:New(holder, config)
    setmetatable(instance, ProficiencyTab)

    local gridConfig = {
        headerText = "Gained Proficiencies",
        noItemsText = "No custom proficiencies gained.",
        maxTableWidth = 4,
        idPrefix = "Proficiency",
        renderItem = function(cell, uuid, data)
            local button = cell:AddButton(data.displayName .. "##AppliedProficiency" .. uuid)
            local popup = cell:AddPopup("ManageProficiency" .. uuid)
            button.OnClick = function() popup:Open() end

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                SMS.ManageProficiency:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    return instance
end

function ProficiencyTab:Init()
    self:Draw()
end

local function _CreateProficiencyButtons(parent, items, columns, id)
    local t = parent:AddTable("ProficiencyTable_" .. id, columns)
    t.SizingFixedFit = true
    local i = 1
    local row
    for _, item in ipairs(items) do
        if (i - 1) % columns == 0 then
            row = t:AddRow()
        end
        local btn = row:AddCell():AddButton(item.name)
        btn.OnClick = function()
            SMS.ManageProficiency:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, boostString = item.boost, displayName = item.name })
        end
        i = i + 1
    end
end

function ProficiencyTab:Draw()
    if self.MainContent then
        UI_Utils.DestroyChildren(self.MainContent)
    else
        self.MainContent = self.Tab:AddGroup("ProficiencyTabMainContent")
    end

    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        self.MainContent:AddText("Select a character to modify proficiencies.")
        return
    end

    local modGroup = self.MainContent:AddGroup("ModifyProficiencies")

    modGroup:AddSeparatorText("Armor Proficiencies")
    _CreateProficiencyButtons(modGroup, proficiencyData.Armor, 4, "Armor")
    modGroup:AddSeparator()

    modGroup:AddSeparatorText("Weapon Proficiencies")
    _CreateProficiencyButtons(modGroup, proficiencyData.Weapons, 4, "Weapons")
    modGroup:AddSeparator()

    modGroup:AddSeparatorText("Saving Throw Proficiencies")
    _CreateProficiencyButtons(modGroup, proficiencyData.SavingThrows, 3, "SavingThrows")
    modGroup:AddSeparator()

    modGroup:AddSeparatorText("Skill Proficiencies & Expertise")
    local skillTable = modGroup:AddTable("SkillProficiencyTable", 3)
    skillTable.SizingFixedFit = true
    for _, skill in ipairs(proficiencyData.Skills) do
        local row = skillTable:AddRow()
        row:AddCell():AddText(skill)
        local profBtn = row:AddCell():AddButton("Proficiency##" .. skill)
        profBtn.OnClick = function()
            local boost = "ProficiencyBonus(Skill," .. skill .. ")"
            SMS.ManageProficiency:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, boostString = boost, displayName = skill .. " Proficiency" })
        end
        local expBtn = row:AddCell():AddButton("Expertise##" .. skill)
        expBtn.OnClick = function()
            local boost = "ExpertiseBonus(" .. skill .. ")"
            SMS.ManageProficiency:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, boostString = boost, displayName = skill .. " Expertise" })
        end
    end
    modGroup:AddSeparator()

    modGroup:AddSeparatorText("Musical Instrument Proficiencies")
    _CreateProficiencyButtons(modGroup, proficiencyData.Instruments, 3, "Instruments")
    modGroup:AddSeparator()

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local appliedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].proficiencies) or {}

    if HLP.Count(appliedForChar) > 0 then
        local clearAllBtn = self.MainContent:AddButton("Clear All Proficiencies")
        clearAllBtn.OnClick = function()
            SMS.ClearAllProficiencyBoosts:SendToServer({ ID = USERID, character = UIState.SelectedCharacter })
        end
    end

    self.ModificationGrid:Draw(appliedForChar)
end

return ProficiencyTab