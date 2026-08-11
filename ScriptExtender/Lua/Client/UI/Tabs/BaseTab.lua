local Pagination = Ext.Require("Client/Utils/Pagination.lua")
local FilterComponent = Ext.Require("Client/UI/Components/FilterComponent.lua")

---@class BaseTab
---@field Tab ExtuiTabItem
---@field InstanceId string
---@field Items table
---@field SearchText string
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchArea ExtuiGroup
---@field PaginationAreaTop ExtuiGroup
---@field MainArea ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
---@field Config table
---@field FilterComponent FilterComponent
BaseTab = {}
BaseTab.__index = BaseTab

function BaseTab:New(holder, config)
    local tabLabel = LCL.Get(config.tabNameHandle, config.tabName)
    local instance = setmetatable({
        InstanceId = HLP.MakeUUID(config.idPrefix .. tostring(Ext.Timer.MonotonicTime()) .. tostring(math.random(1, 1000000))),
        Tab = holder:AddTabItem(tabLabel),
        Items = {},
        SearchText = "",
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        Config = config,
    }, BaseTab)

    -- Create placeholder groups in the desired order.
    instance.ModificationGridArea = instance.Tab:AddGroup(config.idPrefix .. "ModificationGridArea")

    if config.filters then
        local filterGroup = instance.Tab:AddGroup(config.idPrefix .. "Filters")
        instance.FilterComponent = FilterComponent:New(filterGroup, config.filters, function() instance:FetchData(1) end)
    end

    return instance
end

function BaseTab:FetchData(page)
    self.CurrentPage = page or 1
    local fetchMessage = self.Config.fetchMessage
    local payload = { ID = USERID, search = self.SearchText, page = self.CurrentPage, tabInstanceId = self.InstanceId }
    if self.FilterComponent then
        payload = HLP.Merge(payload, self.FilterComponent:GetState())
    end
    if fetchMessage then
        fetchMessage:SendToServer(payload)
    end
end

function BaseTab:SetData(payload)
    UI_Utils.DestroyChildren(self.MainArea)
    UI_Utils.DestroyChildren(self.PaginationAreaTop)
    UI_Utils.DestroyChildren(self.PaginationAreaBottom)

    self.Items = payload.data or {}
    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.MainArea:AddText(self.Config.noItemsText or "No items found.")
        return
    end

    local shownCount = HLP.Count(self.Items)

    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = self.Config.idPrefix .. "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:FetchData(page) end
    })

    self.MainArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")

    self:DrawGrid() -- This will be implemented by the child class

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = self.Config.idPrefix .. "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:FetchData(page) end
    })
end

function BaseTab:AddSearch()
    UI_Utils.DestroyChildren(self.SearchArea)

    self.SearchArea:AddSeparatorText(LCL.Get(self.Config.searchLabelHandle, self.Config.searchLabel or "Search:"))

    local searchInput = self.SearchArea:AddInputText("##Search" .. self.Config.idPrefix, "")
    local searchBtn = self.SearchArea:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search") .. "##" .. self.Config.idPrefix)

    searchBtn.OnClick = function()
        self.SearchText = searchInput.Text
        self:FetchData(1)
    end

    -- Allow child classes to add more buttons to the search area
    if self.AddExtraSearchButtons then
        self:AddExtraSearchButtons(self.SearchArea)
    end

    if self.FilterComponent then
        self.FilterComponent:Draw()
    end
end

function BaseTab:Init()
    self.SearchArea = self.Tab:AddGroup(self.Config.idPrefix .. "Search")
    self.PaginationAreaTop = self.Tab:AddGroup(self.Config.idPrefix .. "PaginationTop")
    self.MainArea = self.Tab:AddGroup(self.Config.idPrefix .. "Items")
    self.PaginationAreaBottom = self.Tab:AddGroup(self.Config.idPrefix .. "PaginationBottom")

    self:AddSearch()
    self:FetchData(1)
end

-- This function MUST be implemented by child classes
function BaseTab:DrawGrid()
    Ext.Utils.PrintError("BaseTab:DrawGrid() must be implemented by child class: " .. self.Config.tabName)
end

return BaseTab