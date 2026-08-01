local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class SpellTab : BaseTab
---@field LearnedSpells table
---@field LearnedSpellsArea ExtuiGroup
SpellTab = {}
setmetatable(SpellTab, { __index = BaseTab })
SpellTab.__index = SpellTab

function SpellTab:New(holder)
    if UI.SpellTab then return end 

    local config = {
        tabName = "Spells",
        idPrefix = "Spell",
        fetchMessage = SMS.FetchSpells,
        searchLabel = "Search Spells:",
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

    local t = self.MainArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
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
        local name = HLP.GetAttr(data, "displayName")

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

        local selectSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432081", "Learn"))
        local removeSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn"))
        removeSpell.SameLine = true

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
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.LearnSpell:SendToServer({ character = charUUID, uuid=uuid, unlearn=1 })
            if self.LearnedSpells[charUUID] then self.LearnedSpells[charUUID][uuid] = nil end
            self:GetLearnedSpells(true)
        end

        selectSpell.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.LearnSpell:SendToServer({ character = charUUID, uuid=uuid, amount=1, data=data })
            if not self.LearnedSpells[charUUID] then self.LearnedSpells[charUUID] = {} end
            self.LearnedSpells[charUUID][uuid] = data
            self:GetLearnedSpells(true)
        end

        i = i + 1

        ::continue::
    end
end

function SpellTab:GetLearnedSpells(noRefetch)
    if not noRefetch then
        self.LearnedSpells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}
    end

    UI.DestroyChildren(self.LearnedSpellsArea)

    local charUUID = UI.CharSelector and UI.CharSelector.SelectedCharacter
    if not charUUID then
        self.LearnedSpellsArea:AddText("Select a character to see their spells.")
        return
    end

    local learnedForChar = self.LearnedSpells[charUUID] or {}
    local totalSpawned = HLP.Count(learnedForChar)
    if totalSpawned == 0 then
        self.LearnedSpellsArea:AddText("You haven't learned any spells.")
        return
    end

    local maxTableWidth = self.Config.maxTableWidth or 5
    local tableWidth = math.min(totalSpawned, maxTableWidth)

    local header = self.LearnedSpellsArea:AddCollapsingHeader("Learned Spells")

    local t = header:AddTable("", tableWidth)
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
        local fullName = HLP.GetAttr(data, "displayName")

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

        local removeSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn"))
        removeSpell.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.LearnSpell:SendToServer({ character = charUUID, uuid=uuid, unlearn=1 })
            if self.LearnedSpells[charUUID] then self.LearnedSpells[charUUID][uuid] = nil end
            self:GetLearnedSpells(true)
        end

        i = i + 1
        drawnCount = drawnCount + 1

        ::continue::
    end
end

return SpellTab