local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class SkillsTab
---@field Tab ExtuiTabItem
---@field Skills table
---@field BoostAmounts number[]
---@field ModificationGrid ModificationGrid
---@field MainContent ExtuiGroup
SkillsTab = {}
setmetatable(SkillsTab, { __index = BaseTab })
SkillsTab.__index = SkillsTab

function SkillsTab:New(holder)
    local config = {
        tabName = "Skills",
        tabNameHandle = "UCT_SkillTab_Label",
        idPrefix = "Skill"
    }
    local instance = BaseTab:New(holder, config)
    setmetatable(instance, SkillsTab)

    local gridConfig = {
        headerText = "Applied Skill Boosts",
        noItemsText = LCL.Get("UCT_NoCustomSkills", "No custom skill boosts applied."),
        maxTableWidth = 4,
        idPrefix = "Skill",
        renderItem = function(cell, uuid, data)
            local name = data.skillName
            local amount = data.amount
            local displayString = string.format("%s %+d", name, amount)

            local button = cell:AddButton(displayString .. "##AppliedSkill" .. uuid)
            local popup = cell:AddPopup("ManageSkill" .. uuid)
            button.OnClick = function() popup:Open() end

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                SMS.ManageSkill:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    instance.Skills = {
        Strength = { "Athletics" },
        Dexterity = { "Acrobatics", "SleightOfHand", "Stealth" },
        Intelligence = { "Arcana", "History", "Investigation", "Nature", "Religion" },
        Wisdom = { "AnimalHandling", "Insight", "Medicine", "Perception", "Survival" },
        Charisma = { "Deception", "Intimidation", "Performance", "Persuasion" }
    }
    instance.BoostAmounts = { -5, -4, -3, -2, -1, 1, 2, 3, 4, 5 }

    return instance
end

function SkillsTab:Init()
    self:Draw()
end

function SkillsTab:Draw()
    if self.MainContent then
        UI_Utils.DestroyChildren(self.MainContent)
    else
        self.MainContent = self.Tab:AddGroup("SkillTabMainContent")
    end

    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        self.MainContent:AddText(LCL.Get("UCT_SkillTab_SelectCharacter", "Select a character to modify skills."))
        return
    end

    -- Modification section
    local modGroup = self.MainContent:AddGroup("ModifySkills")
    modGroup:AddSeparatorText("Modify Skills")

    -- Create a single table to ensure all columns are aligned
    local modTable = modGroup:AddTable("ModifySkillsTable", #self.BoostAmounts + 1)
    modTable.SizingFixedFit = true

    -- Use a consistent order for abilities
    local abilityOrder = { "Strength", "Dexterity", "Intelligence", "Wisdom", "Charisma" }

    for _, ability in ipairs(abilityOrder) do
        local skills = self.Skills[ability]
        if skills then
            -- Add a separator row for the ability name that spans all columns
            local separatorRow = modTable:AddRow()
            local separatorCell = separatorRow:AddCell()
            separatorCell:AddSeparatorText(ability)

            for _, skill in ipairs(skills) do
                local skillRow = modTable:AddRow()
                skillRow:AddCell():AddText(skill)
                for _, amount in ipairs(self.BoostAmounts) do
                    local btn = skillRow:AddCell():AddButton(string.format("%+d##%s_%d", amount, skill, amount))
                    btn.OnClick = function()
                        SMS.ManageSkill:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, skillName = skill, amount = amount })
                    end
                end
            end
        end
    end

    self.MainContent:AddSeparator()

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local appliedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].skills) or {}

    if HLP.Count(appliedForChar) > 0 then
        local clearAllBtn = self.MainContent:AddButton(LCL.Get("UCT_SkillTab_ClearAll", "Clear All Boosts"))
        clearAllBtn.OnClick = function()
            SMS.ClearAllSkillBoosts:SendToServer({ ID = USERID, character = UIState.SelectedCharacter })
        end
    end

    self.ModificationGrid:Draw(appliedForChar)
end

return SkillsTab