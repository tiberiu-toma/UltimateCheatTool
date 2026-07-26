---@class SpellTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field AllSpells table
---@field ResultCount int
---@field SpellsArea ExtuiCollapsingHeader
---@field SpellSearch ExtuiGroup
---@field LearnedSpells table
---@field LearnedSpellsArea ExtuiGroup
---@field AmountOptions table
SpellTab = {}
SpellTab.__index = SpellTab

---@param holder ExtuiTabBar
function SpellTab:GetAllSpells(search)    
    search = search or ""
    SMS.FetchSpells:SendToServer({ ID=USERID, search=search })
end

function SpellTab:New(holder)
    if UI.SpellTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Spells")),
        AllSpells = {},
        ResultCount = 0,

        LearnedSpells = {},
        
        AmountOptions = {1}
    }, SpellTab)
    return instance
end

function SpellTab:SetSpells(items)
    UI.DestroyChildren(self.SpellsArea)

    self.AllSpells = items
    self.ResultCount = HLP.Count(items)

    local shownCount = HLP.Count(self.AllSpells)

    if shownCount == 0 then
        self.SpellsArea:AddText("No items found.")
        return
    end

    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth) 

    self.SpellsArea:AddText("Showing " .. shownCount .. " items (max: 50)")

    local t = self.SpellsArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.AllSpells) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end
        
        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" then
            goto continue
        end
        local name = HLP.GetAttr(data, "displayName")

        if not name then
            --print("Skipping invalid entry:", uuid)
            goto continue
        end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local SpellItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddItem")

        SpellItem.OnClick = function()
            popup:Open()
        end

        local selectSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432081", "Learn"))
        local removeSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn"))
        
        removeSpell.OnClick = function()
            SMS.LearnSpell:SendToServer({ uuid=uuid,unlearn=1 })

            self.LearnedSpells[uuid] = nil
            self:GetLearnedSpells()
        end

        selectSpell.OnClick = function()
            SMS.LearnSpell:SendToServer({ uuid=uuid, amount=1, data=data })

            self.LearnedSpells[uuid] = data
            self:GetLearnedSpells()
        end

        i = i + 1

        ::continue::
    end

    --print(i .. " total cells added")
end

function SpellTab:GetLearnedSpells()
    UI.DestroyChildren(self.LearnedSpellsArea)

    local totalSpawned = HLP.Count(self.LearnedSpells)

    if totalSpawned == 0 then
        self.LearnedSpellsArea:AddText("You haven't learned any spells.")
        return
    end

    local maxTableWidth = 5
    local tableWidth = math.min(totalSpawned, maxTableWidth) 

    local header = self.LearnedSpellsArea:AddCollapsingHeader("Learned Spells")

    local t = header:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.LearnedSpells) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end
        
        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        local name = HLP.GetAttr(data, "displayName")

        if not name then
            --print("Skipping invalid entry:", uuid)
            goto continue
        end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local SpellItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("ManageSpell")

        SpellItem.OnClick = function()
            popup:Open()
        end

        local selectSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432081", "Learn"))
        local removeSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn"))
        removeSpell.OnClick = function()
            SMS.LearnSpell:SendToServer({ uuid=uuid,unlearn=1 })

            self.LearnedSpells[uuid] = nil
            self:GetLearnedSpells()
        end

        selectSpell.OnClick = function()
            SMS.LearnSpell:SendToServer({ uuid=uuid, amount=1, data=data })

            self.LearnedSpells[uuid] = data
            self:GetLearnedSpells()
        end

        i = i + 1

        ::continue::
    end

    --print(i .. " total cells added")
end

function SpellTab:AddSpellSearch()
    UI.DestroyChildren(self.SpellSearch)

    local sep = self.SpellSearch:AddSeparatorText(LCL.Get("hbea4aec9a88b4a34b615f347cb48d3ed1", "Search Spells:"))

    local search = self.SpellSearch:AddInputText("", "")
    local btn = self.SpellSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        local txt = search.Text 

        self:GetAllSpells(txt)
    end
end

function SpellTab:Init()
    self.LearnedSpells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}
    self.LearnedSpellsArea = self.Tab:AddGroup("LearnedSpells")

    self:GetLearnedSpells()

    self.SpellSearch = self.Tab:AddGroup("SpellSearch")
    self.SpellsArea = self.Tab:AddGroup("AllSpells")

    self:AddSpellSearch()

    self.AllSpells = {}
    self:GetAllSpells()
end

return SpellTab