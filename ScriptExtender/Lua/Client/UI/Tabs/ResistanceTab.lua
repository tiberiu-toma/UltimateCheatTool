local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class ResistanceTab
---@field Tab ExtuiTabItem
---@field MainContent ExtuiGroup
---@field ModificationGrid ModificationGrid
ResistanceTab = {}
setmetatable(ResistanceTab, { __index = BaseTab })
ResistanceTab.__index = ResistanceTab

local damageTypes = { "Bludgeoning", "Piercing", "Slashing", "Acid", "Cold", "Fire", "Force", "Lightning", "Necrotic", "Poison", "Psychic", "Radiant", "Thunder" }
local resistanceTypes = { "Immune", "Resistant", "Vulnerable" }

function ResistanceTab:New(holder)
    local config = {
        tabName = "Resistances",
        tabNameHandle = "UCT_ResistanceTab_Label",
        idPrefix = "Resistance"
    }
    local instance = BaseTab:New(holder, config)
    setmetatable(instance, ResistanceTab)

    local gridConfig = {
        headerText = "Gained Resistances",
        noItemsText = "No custom resistances, vulnerabilities, or immunities gained.",
        maxTableWidth = 4,
        idPrefix = "Resistance",
        renderItem = function(cell, uuid, data)
            local button = cell:AddButton(data.displayName .. "##AppliedResistance" .. uuid)
            local popup = cell:AddPopup("ManageResistance" .. uuid)
            button.OnClick = function() popup:Open() end

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                SMS.ManageResistance:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    return instance
end

function ResistanceTab:Init()
    self:Draw()
end

function ResistanceTab:Draw()
    if self.MainContent then
        UI_Utils.DestroyChildren(self.MainContent)
    else
        self.MainContent = self.Tab:AddGroup("ResistanceTabMainContent")
    end

    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        self.MainContent:AddText("Select a character to modify resistances.")
        return
    end

    local modGroup = self.MainContent:AddGroup("ModifyResistances")
    modGroup:AddSeparatorText("Modify Damage Resistances")

    local resTable = modGroup:AddTable("ResistanceTable", #resistanceTypes + 1)
    resTable.SizingFixedFit = true

    -- Header row
    local headerRow = resTable:AddRow()
    headerRow:AddCell():AddText("Damage Type")
    for _, resType in ipairs(resistanceTypes) do
        headerRow:AddCell():AddText(resType)
    end

    -- Data rows
    for _, dmgType in ipairs(damageTypes) do
        local row = resTable:AddRow()
        row:AddCell():AddText(dmgType)
        for _, resType in ipairs(resistanceTypes) do
            local btn = row:AddCell():AddButton("Add##" .. dmgType .. resType)
            btn.OnClick = function()
                local boost = string.format("Resistance(%s,%s)", dmgType, resType)
                local displayName = string.format("%s %s", dmgType, resType)
                SMS.ManageResistance:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, boostString = boost, displayName = displayName })
            end
        end
    end

    self.MainContent:AddSeparator()

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local appliedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].resistances) or {}

    if HLP.Count(appliedForChar) > 0 then
        local clearAllBtn = self.MainContent:AddButton("Clear All Resistances")
        clearAllBtn.OnClick = function()
            SMS.ClearAllResistanceBoosts:SendToServer({ ID = USERID, character = UIState.SelectedCharacter })
        end
    end

    self.ModificationGrid:Draw(appliedForChar)
end

return ResistanceTab