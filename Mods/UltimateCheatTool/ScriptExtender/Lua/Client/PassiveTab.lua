local Pagination = Ext.Require("Client/Pagination.lua")

---@class PassiveTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field AllPassives table
---@field ResultCount int
---@field PassivesArea ExtuiCollapsingHeader
---@field PassiveSearch ExtuiGroup
---@field LearnedPassives table
---@field LearnedPassivesArea ExtuiGroup
---@field AmountOptions table
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchText string
---@field PaginationAreaTop ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
PassiveTab = {}
PassiveTab.__index = PassiveTab

---@param holder ExtuiTabBar
function PassiveTab:GetAllPassives(page)
    self.CurrentPage = page or 1
    SMS.FetchPassives:SendToServer({ ID=USERID, search=self.SearchText, page=self.CurrentPage })
end

function PassiveTab:New(holder)
    if UI.PassiveTab then return end

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Passives")),
        AllPassives = {},
        ResultCount = 0,
        LearnedPassives = {},
        AmountOptions = {1},
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        SearchText = ""
        -- PaginationAreaTop and PaginationAreaBottom will be initialized in Init()
    }, PassiveTab)
    return instance
end

function PassiveTab:SetPassives(payload)
    UI.DestroyChildren(self.PassivesArea)
    UI.DestroyChildren(self.PaginationAreaTop)
    UI.DestroyChildren(self.PaginationAreaBottom)

    local items = payload.data
    self.AllPassives = items
    self.ResultCount = HLP.Count(items)

    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.PassivesArea:AddText("No passives found.")
        -- No pagination controls needed if there are no items.
        return
    end

    local shownCount = HLP.Count(self.AllPassives)
    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth)
    
    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllPassives(page) end
    })

    self.PassivesArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")

    local t = self.PassivesArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.AllPassives) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end

        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" or icon == "" then
            icon = "EC_Portrait_Generic"
        end
        local name = HLP.GetAttr(data, "displayName")

        if not name then
            goto continue
        end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local PassiveItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddPassive")

        PassiveItem.OnClick = function()
            popup:Open()
        end

        local selectPassive = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432081", "Learn"))
        local removePassive = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn"))

        removePassive.OnClick = function()
            SMS.LearnPassive:SendToServer({ uuid=uuid, unlearn=1})
            self.LearnedPassives[uuid] = nil
            self:GetLearnedPassives()
        end

        selectPassive.OnClick = function()
            SMS.LearnPassive:SendToServer({ uuid=uuid, amount=1, data=data })
            self.LearnedPassives[uuid] = data
            self:GetLearnedPassives()
        end

        i = i + 1

        ::continue::
    end

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllPassives(page) end
    })
end

function PassiveTab:GetLearnedPassives()
    UI.DestroyChildren(self.LearnedPassivesArea)

    local totalSpawned = HLP.Count(self.LearnedPassives)

    if totalSpawned == 0 then
        self.LearnedPassivesArea:AddText("You haven't learned any passives.")
        return
    end

    local maxTableWidth = 5
    local tableWidth = math.min(totalSpawned, maxTableWidth)

    local header = self.LearnedPassivesArea:AddCollapsingHeader("Learned Passives")

    local t = header:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.LearnedPassives) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end

        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" or icon == "" then
            icon = "EC_Portrait_Generic"
        end
        local name = HLP.GetAttr(data, "displayName")

        if not name then
            goto continue
        end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local PassiveItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("ManagePassive")

        PassiveItem.OnClick = function()
            popup:Open()
        end

        local removePassive = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432082", "Unlearn"))
        removePassive.OnClick = function()
            SMS.LearnPassive:SendToServer({ uuid=uuid,unlearn=1 })
            self.LearnedPassives[uuid] = nil
            self:GetLearnedPassives()
        end

        i = i + 1

        ::continue::
    end
end

function PassiveTab:AddPassiveSearch()
    UI.DestroyChildren(self.PassiveSearch)

    local sep = self.PassiveSearch:AddSeparatorText(LCL.Get("", "Search Passives:"))

    local search = self.PassiveSearch:AddInputText("", "")
    local btn = self.PassiveSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        self.SearchText = search.Text
        self:GetAllPassives(1)
    end
end

function PassiveTab:Init()
    self.LearnedPassives = Ext.Vars.GetModVariables(ModuleUUID).LearnedPassives or {}
    self.LearnedPassivesArea = self.Tab:AddGroup("LearnedPassives")

    self:GetLearnedPassives()

    self.PassiveSearch = self.Tab:AddGroup("PassiveSearch")
    self.PaginationAreaTop = self.Tab:AddGroup("PaginationAreaTop")
    self.PassivesArea = self.Tab:AddGroup("AllPassives")
    self.PaginationAreaBottom = self.Tab:AddGroup("PaginationAreaBottom")

    self:AddPassiveSearch()

    self.AllPassives = {}
    self:GetAllPassives(1)
end

return PassiveTab