local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class SpellTab : BaseTab
---@field LearnedSpells table
---@field LearnedSpellsArea ExtuiGroup
SpellTab = {}
setmetatable(SpellTab, { __index = BaseTab })
SpellTab.__index = SpellTab

function SpellTab:New(holder)
    local config = {
        tabName = "Spells",
        tabNameHandle = "UCT_SpellTab_Label",
        idPrefix = "Spell",
        fetchMessage = SMS.FetchSpells,
        searchLabel = "Search Spells:",
        searchLabelHandle = "UCT_SearchSpells_Label",
        noItemsText = "No spells found.",
        maxTableWidth = 5
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, SpellTab) -- Re-set metatable to the child class

    local gridConfig = {
        headerText = LCL.Get("UCT_LearnedSpellsHeader", "Learned Spells"),
        noItemsText = LCL.Get("UCT_SpellTab_NoLearnedSpells", "This character has no custom learned spells."),
        maxTableWidth = 5,
        idPrefix = "Spell",
        renderItem = function(cell, uuid, spellMod)
            local data = spellMod.data
            local icon = HLP.GetAttr(data, "icon")
            local fullName = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

            if not fullName then return end

            local name = fullName
            if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

            local spellItem = cell:AddImageButton("##LearnedSpell" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("ManageSpell" .. uuid)

            spellItem.OnClick = function() popup:Open() end

            InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" } })

            local removeSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn") .. "##" .. uuid)
            removeSpell.OnClick = function() SMS.LearnSpell:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, unlearn=1 }) end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.Tab:AddGroup("LearnedSpells"), gridConfig)

    return instance
end

function SpellTab:Init()
    self:GetLearnedSpells()

    -- This will create the search, pagination, and main areas and fetch the first page of all spells
    BaseTab.Init(self)
end

---Populates a popup with ability selection buttons.
---@param popup ExtuiPopup The popup to populate.
---@param title string The title to display in the popup.
---@param onSelect function The callback function to execute when an ability is selected.
function SpellTab:_PopulateAbilityPopup(popup, title, onSelect)
    -- Use OnOpen to rebuild the popup content each time, ensuring it's fresh.
    UI_Utils.DestroyChildren(popup)
    popup:AddText(title)
    popup:AddSeparator()
    for _, ability in ipairs({"Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma"}) do
        local abilityBtn = popup:AddButton(ability)
        abilityBtn.OnClick = function()
            onSelect(ability)
        end
    end
end

function SpellTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("SpellGrid", tableWidth)
    t.SizingFixedSame = false
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end
        
        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" or icon == "" then
            icon = "EC_Portrait_Generic"
        end
        local name = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

        if name then
            local fullName = name
            if HLP.Strlen(name) > 20 then
                name = HLP.Cut(name, 1, 20) .. "..."
            end

            local cell = row:AddCell()
            local spellItem = cell:AddImageButton("##Spell" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("AddItem" .. uuid)
            local abilityPopup = cell:AddPopup("AbilityPopup" .. uuid)
            local partyAbilityPopup = cell:AddPopup("PartyAbilityPopup" .. uuid)

            spellItem.OnClick = function() popup:Open() end

            local actionsTable = popup:AddTable("SpellActionsTable" .. uuid, 2)
            actionsTable.SizingFixedSame = false
            actionsTable.NoHostExtendX = true

            local row1 = actionsTable:AddRow()
            local selectSpell = row1:AddCell():AddButton(LCL.Get("hc056102aefe641d4be93e011426432081", "Learn") .. "##Learn" .. uuid)
            local removeSpell = row1:AddCell():AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn") .. "##Unlearn" .. uuid)
            local row2 = actionsTable:AddRow()
            local learnForParty = row2:AddCell():AddButton(LCL.Get("UCT_SpellTab_LearnForParty", "Learn for Party") .. "##LearnParty" .. uuid)
            local unlearnForParty = row2:AddCell():AddButton(LCL.Get("UCT_SpellTab_UnlearnForParty", "Unlearn for Party") .. "##UnlearnParty" .. uuid)

            data.fullName = fullName
            local spellInfoFields = 
            {
                { key = "id", label = "ID" },
                { key = "fullName", label = "Name" },
                { key = "spellType", label = "Spell Type" },
                { key = "spellSchool", label = "Spell School" },
                { key = "useCosts", label = "Use Costs" },
                { key = "level", label = "Level" },
                { key = "cooldown", label = "Cooldown" },
                { key = "modName", label = "Mod Name" },
            }
            InfoPopup:AddInfo(popup, data, spellInfoFields)
            
            selectSpell.OnClick = function()
                self:_PopulateAbilityPopup(abilityPopup, "Select Casting Ability:", function(ability)
                    SMS.LearnSpell:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, data=data, ability = ability })
                end)
                abilityPopup:Open()
            end

            removeSpell.OnClick = function()
                SMS.LearnSpell:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, unlearn=1 })
            end

            learnForParty.OnClick = function()
                self:_PopulateAbilityPopup(partyAbilityPopup, "Select Casting Ability for Party:", function(ability)
                    SMS.LearnSpellForParty:SendToServer({ ID = USERID, uuid = uuid, data = data, ability = ability })
                end)
                partyAbilityPopup:Open()
            end

            unlearnForParty.OnClick = function()
                SMS.UnlearnSpellForParty:SendToServer({ ID = USERID, uuid = uuid })
            end
            i = i + 1
        end
    end
end

function SpellTab:GetLearnedSpells()
    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
        self.ModificationGrid.Parent:AddText(LCL.Get("UCT_SpellTab_SelectCharacter", "Select a character to see their learned spells."))
        return
    end

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local learnedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].spells) or {}
    self.ModificationGrid:Draw(learnedForChar)
end

return SpellTab