local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")

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
    instance.LearnedSpells = {}
    return instance
end

function SpellTab:Init()
    self.LearnedSpellsArea = self.Tab:AddGroup("LearnedSpells")
    self:GetLearnedSpells()

    -- This will create the search, pagination, and main areas and fetch the first page of all spells
    BaseTab.Init(self)
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

        if not name then
            goto continue
        end

        local fullName = name
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local spellItem = cell:AddImageButton("##Spell" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddItem" .. uuid)

        spellItem.OnClick = function()
            popup:Open()
        end

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
        local spellInfoFields = {
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
        
        removeSpell.OnClick = function()
            SMS.LearnSpell:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, unlearn=1 })
        end

        selectSpell.OnClick = function()
            SMS.LearnSpell:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, amount=1, data=data })
        end

        learnForParty.OnClick = function()
            SMS.LearnSpellForParty:SendToServer({ ID = USERID, uuid = uuid, data = data })
        end

        unlearnForParty.OnClick = function()
            SMS.UnlearnSpellForParty:SendToServer({ ID = USERID, uuid = uuid })
        end

        i = i + 1

        ::continue::
    end
end

function SpellTab:GetLearnedSpells()
    self.LearnedSpells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}

    UI_Utils.DestroyChildren(self.LearnedSpellsArea)

    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        self.LearnedSpellsArea:AddText(LCL.Get("UCT_SpellTab_SelectCharacter", "Select a character to see their spells."))
        return
    end

    local learnedForChar = self.LearnedSpells[charUUID] or {}
    local totalSpawned = HLP.Count(learnedForChar)
    if totalSpawned == 0 then
        self.LearnedSpellsArea:AddText(LCL.Get("UCT_SpellTab_NoLearnedSpells", "You haven't learned any spells."))
        return
    end

    local maxTableWidth = self.Config.maxTableWidth or 5
    local tableWidth = math.min(totalSpawned, maxTableWidth)

    local header = self.LearnedSpellsArea:AddCollapsingHeader(LCL.Get("UCT_LearnedSpellsHeader", "Learned Spells"))

    local t = header:AddTable("LearnedSpellsGrid", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row
    local drawnCount = 0
    local maxDrawn = 50 -- Performance cap

    for uuid,data in kpairs(learnedForChar) do
        if drawnCount >= maxDrawn then
            header:AddText("...and more (list truncated for performance).")
            break
        end

        if (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end
        
        local icon = HLP.GetAttr(data, "icon")
        local fullName = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

        if not fullName then
            goto continue
        end

        local name = fullName
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local spellItem = cell:AddImageButton("##LearnedSpell" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("ManageSpell" .. uuid)

        spellItem.OnClick = function()
            popup:Open()
        end

        data.fullName = fullName
        local learnedSpellInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, learnedSpellInfoFields)

        local removeSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn") .. "##" .. uuid)
        removeSpell.OnClick = function()
            SMS.LearnSpell:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, unlearn=1 })
        end

        i = i + 1


        drawnCount = drawnCount + 1

        ::continue::
    end
end

return SpellTab