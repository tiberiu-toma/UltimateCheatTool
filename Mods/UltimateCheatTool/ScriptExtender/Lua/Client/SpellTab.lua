local Pagination = Ext.Require("Client/Pagination.lua")

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
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchText string
---@field PaginationAreaTop ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
SpellTab = {}
SpellTab.__index = SpellTab

---@param holder ExtuiTabBar
function SpellTab:GetAllSpells(page)
    self.CurrentPage = page or 1
    SMS.FetchSpells:SendToServer({ ID=USERID, search=self.SearchText, page=self.CurrentPage })
end

function SpellTab:New(holder)
    if UI.SpellTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Spells")),
        AllSpells = {},
        ResultCount = 0,
        LearnedSpells = {},
        AmountOptions = {1},
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        SearchText = ""
    }, SpellTab)
    return instance
end

function SpellTab:SetSpells(payload)
    UI.DestroyChildren(self.SpellsArea)
    UI.DestroyChildren(self.PaginationAreaTop)
    UI.DestroyChildren(self.PaginationAreaBottom)

    local items = payload.data
    self.AllSpells = items
    self.ResultCount = HLP.Count(items)

    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.SpellsArea:AddText("No items found.")
        return
    end

    local shownCount = HLP.Count(self.AllSpells)
    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth) 

    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllSpells(page) end
    })

    self.SpellsArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")

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
        if not icon or icon == "unknown" or icon == "" then
            icon = "EC_Portrait_Generic"
        end
        local name = HLP.GetAttr(data, "displayName")
        local spellType = HLP.GetAttr(data, "spellType")
        local spellSchool = HLP.GetAttr(data, "spellSchool")
        local useCosts = HLP.GetAttr(data, "useCosts")
        local level = HLP.GetAttr(data, "level")
        local cooldown = HLP.GetAttr(data, "cooldown")
        local modName = HLP.GetAttr(data, "modName")

        if not name then
            --print("Skipping invalid entry:", uuid)
            goto continue
        end

        local fullName = name
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
        local idPopup = popup:AddText(uuid)
        local namePopup = popup:AddText(fullName)
        local spellType = popup:AddText("Spell Type: " .. (spellType or "N/A"))
        local spellSchool = popup:AddText("Spell School: " .. (spellSchool or "N/A"))
        local useCosts = popup:AddText("Use Costs: " .. (useCosts or "N/A"))
        local level = popup:AddText("Level: " .. (level or "N/A"))
        local cooldown = popup:AddText("Cooldown: " .. (cooldown or "N/A"))
        local modName = popup:AddText("Mod Name: " .. (modName or "N/A"))

        removeSpell.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.LearnSpell:SendToServer({ character = charUUID, uuid=uuid, unlearn=1 })
            if self.LearnedSpells[charUUID] then self.LearnedSpells[charUUID][uuid] = nil end
            self:GetLearnedSpells()
        end

        selectSpell.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.LearnSpell:SendToServer({ character = charUUID, uuid=uuid, amount=1, data=data })
            if not self.LearnedSpells[charUUID] then self.LearnedSpells[charUUID] = {} end
            self.LearnedSpells[charUUID][uuid] = data
            self:GetLearnedSpells()
        end

        i = i + 1

        ::continue::
    end

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllSpells(page) end
    })
end

function SpellTab:GetLearnedSpells()
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

    local maxTableWidth = 5
    local tableWidth = math.min(totalSpawned, maxTableWidth) 

    local header = self.LearnedSpellsArea:AddCollapsingHeader("Learned Spells")

    local t = header:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(learnedForChar) do
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

        local idPopup = popup:AddText(uuid)
        local namePopup = popup:AddText(name)
        local removeSpell = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn"))
        removeSpell.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.LearnSpell:SendToServer({ character = charUUID, uuid=uuid, unlearn=1 })
            if self.LearnedSpells[charUUID] then self.LearnedSpells[charUUID][uuid] = nil end
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
        self.SearchText = search.Text
        self:GetAllSpells(1)
    end
end

function SpellTab:Init()
    self.LearnedSpells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}
    self.LearnedSpellsArea = self.Tab:AddGroup("LearnedSpells")

    self:GetLearnedSpells()

    self.SpellSearch = self.Tab:AddGroup("SpellSearch")
    self.PaginationAreaTop = self.Tab:AddGroup("PaginationAreaTop")
    self.SpellsArea = self.Tab:AddGroup("AllSpells")
    self.PaginationAreaBottom = self.Tab:AddGroup("PaginationAreaBottom")

    self:AddSpellSearch()

    self.AllSpells = {}
    self:GetAllSpells(1)
end

return SpellTab