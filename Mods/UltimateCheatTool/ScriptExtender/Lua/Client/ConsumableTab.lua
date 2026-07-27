local Pagination = Ext.Require("Client/Pagination.lua")

---@class ConsumableTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field ConsumableItems table
---@field ResultCount int
---@field ConsumableArea ExtuiCollapsingHeader
---@field ConsumableSearch ExtuiGroup
---@field AmountOptions table
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchText string
---@field PaginationAreaTop ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
ConsumableTab = {}
ConsumableTab.__index = ConsumableTab

---@param holder ExtuiTabBar
function ConsumableTab:GetConsumableItems(page)
    self.CurrentPage = page or 1
    SMS.FetchConsumables:SendToServer({ ID=USERID, search=self.SearchText, page=self.CurrentPage })
end

function ConsumableTab:New(holder)
    if UI.ConsumableTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Consumables")),
        ConsumableItems = {},
        ResultCount = 0,
        AmountOptions = {1, 2, 5, 10, 99},
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        SearchText = ""
    }, ConsumableTab)
    return instance
end

function ConsumableTab:SetConsumables(payload)
    UI.DestroyChildren(self.ConsumableArea)
    UI.DestroyChildren(self.PaginationAreaTop)
    UI.DestroyChildren(self.PaginationAreaBottom)

    local items = payload.data
    self.ConsumableItems = items
    self.ResultCount = HLP.Count(items)

    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.ConsumableArea:AddText("No items found.")
        return
    end

    local shownCount = HLP.Count(self.ConsumableItems)
    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth) 

    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetConsumableItems(page) end
    })

    self.ConsumableArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")
    
    local t = self.ConsumableArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.ConsumableItems) do
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
        local ConsumableItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddItem")

        ConsumableItem.OnClick = function()
            popup:Open()
        end

        for _,num in kpairs(self.AmountOptions) do
            local selectConsumable = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn") .. " " .. num)

            selectConsumable.OnClick = function()
                SMS.SpawnTemplate:SendToServer({ uuid=uuid, amount=num })
            end
        end

        i = i + 1

        ::continue::
    end

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetConsumableItems(page) end
    })
end

function ConsumableTab:AddConsumableSearch()
    UI.DestroyChildren(self.ConsumableSearch)

    local sep = self.ConsumableSearch:AddSeparatorText(LCL.Get("hbea4aec9a88b4a34b615f347cb48d3ed1", "Search Consumable:"))

    local search = self.ConsumableSearch:AddInputText("", "")
    local btn = self.ConsumableSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        self.SearchText = search.Text 
        self:GetConsumableItems(1)
    end
end

function ConsumableTab:Init()
    self.ConsumableSearch = self.Tab:AddGroup("ConsumableSearch")
    self.PaginationAreaTop = self.Tab:AddGroup("PaginationAreaTop")
    self.ConsumableArea = self.Tab:AddGroup("ConsumableItems")
    self.PaginationAreaBottom = self.Tab:AddGroup("PaginationAreaBottom")

    self:AddConsumableSearch()

    self.ConsumableItems = {}
    self:GetConsumableItems(1)
end

return ConsumableTab