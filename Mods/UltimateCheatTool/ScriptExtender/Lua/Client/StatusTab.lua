local Pagination = Ext.Require("Client/Pagination.lua")

---@class StatusTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field AllStatuses table
---@field ResultCount int
---@field StatusesArea ExtuiCollapsingHeader
---@field StatusSearch ExtuiGroup
---@field AppliedStatuses table
---@field AppliedStatusesArea ExtuiGroup
---@field AmountOptions table
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchText string
---@field PaginationAreaTop ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
StatusTab = {}
StatusTab.__index = StatusTab

---@param holder ExtuiTabBar
function StatusTab:GetAllStatuses(page)
    self.CurrentPage = page or 1
    SMS.FetchStatuses:SendToServer({ ID=USERID, search=self.SearchText, page=self.CurrentPage })
end

function StatusTab:New(holder)
    if UI.StatusTab then return end

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Statuses")),
        AllStatuses = {},
        ResultCount = 0,
        AppliedStatuses = {},
        AmountOptions = {1},
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        SearchText = ""
    }, StatusTab)
    return instance
end

function StatusTab:SetStatuses(payload)
    UI.DestroyChildren(self.StatusesArea)
    UI.DestroyChildren(self.PaginationAreaTop)
    UI.DestroyChildren(self.PaginationAreaBottom)

    local items = payload.data
    self.AllStatuses = items
    self.ResultCount = HLP.Count(items)

    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.StatusesArea:AddText("No statuses found.")
        return
    end

    local shownCount = HLP.Count(self.AllStatuses)
    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth)

    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllStatuses(page) end
    })

    self.StatusesArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")
    
    local t = self.StatusesArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.AllStatuses) do
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
        local StatusItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddStatus")

        StatusItem.OnClick = function()
            popup:Open()
        end

        local applyStatus = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432083", "Apply"))
        local removeStatus = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432084", "Remove"))

        removeStatus.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ApplyStatus:SendToServer({ character = charUUID, uuid=uuid, remove=1 })
            if self.AppliedStatuses[charUUID] then self.AppliedStatuses[charUUID][uuid] = nil end
            self:GetAppliedStatuses()
        end

        applyStatus.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ApplyStatus:SendToServer({ character = charUUID, uuid=uuid, amount=1, data=data })
            if not self.AppliedStatuses[charUUID] then self.AppliedStatuses[charUUID] = {} end
            self.AppliedStatuses[charUUID][uuid] = data
            self:GetAppliedStatuses()
        end

        i = i + 1

        ::continue::
    end

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetAllStatuses(page) end
    })
end

function StatusTab:GetAppliedStatuses()
    UI.DestroyChildren(self.AppliedStatusesArea)

    local charUUID = UI.CharSelector and UI.CharSelector.SelectedCharacter
    if not charUUID then
        self.AppliedStatusesArea:AddText("Select a character to see their statuses.")
        return
    end

    local appliedForChar = self.AppliedStatuses[charUUID] or {}
    local totalSpawned = HLP.Count(appliedForChar)
    if totalSpawned == 0 then
        self.AppliedStatusesArea:AddText("You don't have any custom statuses applied.")
        return
    end

    local maxTableWidth = 5
    local tableWidth = math.min(totalSpawned, maxTableWidth)

    local header = self.AppliedStatusesArea:AddCollapsingHeader("Applied Statuses")

    local t = header:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(appliedForChar) do
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
        local StatusItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("ManageStatus")

        StatusItem.OnClick = function()
            popup:Open()
        end

        local removeStatus = popup:AddButton(LCL.Get("hc056102aefe641d4be93e011426432084", "Remove"))
        removeStatus.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ApplyStatus:SendToServer({ character = charUUID, uuid=uuid, remove=1 })
            if self.AppliedStatuses[charUUID] then self.AppliedStatuses[charUUID][uuid] = nil end
            self:GetAppliedStatuses()
        end

        i = i + 1

        ::continue::
    end
end

function StatusTab:AddStatusSearch()
    UI.DestroyChildren(self.StatusSearch)

    local sep = self.StatusSearch:AddSeparatorText(LCL.Get("", "Search Statuses:"))

    local search = self.StatusSearch:AddInputText("", "")
    local btn = self.StatusSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        self.SearchText = search.Text
        self:GetAllStatuses(1)
    end
end

function StatusTab:Init()
    self.AppliedStatuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
    self.AppliedStatusesArea = self.Tab:AddGroup("AppliedStatuses")

    self:GetAppliedStatuses()

    self.StatusSearch = self.Tab:AddGroup("StatusSearch")
    self.PaginationAreaTop = self.Tab:AddGroup("PaginationAreaTop")
    self.StatusesArea = self.Tab:AddGroup("AllStatuses")
    self.PaginationAreaBottom = self.Tab:AddGroup("PaginationAreaBottom")

    self:AddStatusSearch()

    self.AllStatuses = {}
    self:GetAllStatuses(1)
end

return StatusTab