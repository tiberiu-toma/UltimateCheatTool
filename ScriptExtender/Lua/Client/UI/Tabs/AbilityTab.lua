local UIState = Ext.Require("Client/UI/UIState.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class AbilityTab
AbilityTab = {}
AbilityTab.__index = AbilityTab

function AbilityTab:New(holder)
    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("UCT_AbilityTab_Label", "Abilities")),
        Abilities = { "Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma" },
        BoostAmounts = { -5, -4, -3, -2, -1, 1, 2, 3, 4, 5 },
        AbilityScores = {},
        LastFetchedChar = nil
    }, AbilityTab)

    local gridConfig = {
        headerText = "Applied Ability Boosts",
        noItemsText = LCL.Get("UCT_NoCustomAbilities", "No custom ability boosts applied."),
        maxTableWidth = 4,
        idPrefix = "Ability",
        renderItem = function(cell, uuid, data)
            local name = data.abilityName
            local amount = data.amount
            local displayString = string.format("%s %+d", name, amount)

            local button = cell:AddButton(displayString .. "##AppliedAbility" .. uuid)
            local popup = cell:AddPopup("ManageAbility" .. uuid)
            button.OnClick = function() popup:Open() end

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                SMS.ManageAbility:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(nil, gridConfig)

    return instance
end

function AbilityTab:Init()
    self:FetchAbilities(true)
    self:Draw()
end

function AbilityTab:FetchAbilities(force)
    local charUUID = UIState.SelectedCharacter
    if not charUUID then return end

    local characterChanged = (self.LastFetchedChar ~= charUUID)

    if force or characterChanged then
        self.LastFetchedChar = charUUID
        if characterChanged then
            self.AbilityScores = {} -- Clear scores only when character changes
            if self.Tab.Visible then self:Draw() end -- Redraw to show loading state
        end
        SMS.FetchAbilities:SendToServer({ ID = USERID, character = charUUID })
    end
end

function AbilityTab:UpdateAbilityScores(payload)
    if payload.character == self.LastFetchedChar then
        self.AbilityScores = payload.scores
        if self.Tab.Visible then
            self:Draw()
        end
    end
end

function AbilityTab:Draw()
    if self.MainContent then
        UI_Utils.DestroyChildren(self.MainContent)
    else
        self.MainContent = self.Tab:AddGroup("AbilityTabMainContent")
    end

    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        self.MainContent:AddText(LCL.Get("UCT_AbilityTab_SelectCharacter", "Select a character to view and modify abilities."))
        self.LastFetchedChar = nil -- Reset fetch state
        return
    end

    -- Fetch data if character has changed
    if self.LastFetchedChar ~= charUUID then
        self:FetchAbilities(true)
    end

    -- Current abilities display
    local currentStatsGroup = self.MainContent:AddGroup("CurrentAbilities")
    currentStatsGroup:AddSeparatorText("Current Abilities")
    local statsTable = currentStatsGroup:AddTable("CurrentAbilitiesTable", 2)
    statsTable.SizingFixedSame = true

    for _, ability in ipairs(self.Abilities) do
        local row = statsTable:AddRow()
        row:AddCell():AddText(ability .. ":")
        local statValue = self.AbilityScores[ability] or "..."
        row:AddCell():AddText(tostring(statValue))
    end

    self.MainContent:AddSeparator()

    -- Modification section
    local modGroup = self.MainContent:AddGroup("ModifyAbilities")
    modGroup:AddSeparatorText("Modify Abilities")
    local modTable = modGroup:AddTable("ModifyAbilitiesTable", #self.BoostAmounts + 1)
    modTable.SizingFixedFit = true

    for _, ability in ipairs(self.Abilities) do
        local abilityRow = modTable:AddRow()
        abilityRow:AddCell():AddText(ability)
        for _, amount in ipairs(self.BoostAmounts) do
            local btn = abilityRow:AddCell():AddButton(string.format("%+d##%s_%d", amount, ability, amount))
            btn.OnClick = function()
                SMS.ManageAbility:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, abilityName = ability, amount = amount })
            end
        end
    end

    self.MainContent:AddSeparator()

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local appliedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].abilities) or {}

    if HLP.Count(appliedForChar) > 0 then
        local clearAllBtn = self.MainContent:AddButton(LCL.Get("UCT_AbilityTab_ClearAll", "Clear All Boosts"))
        clearAllBtn.OnClick = function()
            SMS.ClearAllAbilityBoosts:SendToServer({ ID = USERID, character = UIState.SelectedCharacter })
        end
    end

    self.ModificationGrid.Parent = self.MainContent:AddGroup("AppliedAbilities")
    self.ModificationGrid:Draw(appliedForChar)
end

return AbilityTab