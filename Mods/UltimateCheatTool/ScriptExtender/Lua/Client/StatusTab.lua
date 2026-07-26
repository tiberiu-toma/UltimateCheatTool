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
StatusTab = {}
StatusTab.__index = StatusTab

---@param holder ExtuiTabBar
function StatusTab:GetAllStatuses(search)
    search = search or ""
    SMS.FetchStatuses:SendToServer({ ID=USERID, search=search })
end

function StatusTab:New(holder)
    if UI.StatusTab then return end

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Statuses")),
        AllStatuses = {},
        ResultCount = 0,
        AppliedStatuses = {},
        AmountOptions = {1}
    }, StatusTab)
    return instance
end

function StatusTab:SetStatuses(items)
    UI.DestroyChildren(self.StatusesArea)

    self.AllStatuses = items
    self.ResultCount = HLP.Count(items)

    local shownCount = HLP.Count(self.AllStatuses)

    if shownCount == 0 then
        self.StatusesArea:AddText("No statuses found.")
        return
    end

    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth)

    self.StatusesArea:AddText("Showing " .. shownCount .. " items (max: 50)")

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
        if not icon or icon == "unknown" then
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
            SMS.ApplyStatus:SendToServer({ uuid=uuid, remove=1 })
            self.AppliedStatuses[uuid] = nil
            self:GetAppliedStatuses()
        end

        applyStatus.OnClick = function()
            SMS.ApplyStatus:SendToServer({ uuid=uuid, amount=1, data=data })
            self.AppliedStatuses[uuid] = data
            self:GetAppliedStatuses()
        end

        i = i + 1

        ::continue::
    end
end

function StatusTab:GetAppliedStatuses()
    UI.DestroyChildren(self.AppliedStatusesArea)

    local totalSpawned = HLP.Count(self.AppliedStatuses)

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

    for uuid,data in kpairs(self.AppliedStatuses) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end

        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" then
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
            SMS.ApplyStatus:SendToServer({ uuid=uuid, remove=1 })
            self.AppliedStatuses[uuid] = nil
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
        local txt = search.Text
        self:GetAllStatuses(txt)
    end
end

function StatusTab:Init()
    self.AppliedStatuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
    self.AppliedStatusesArea = self.Tab:AddGroup("AppliedStatuses")

    self:GetAppliedStatuses()

    self.StatusSearch = self.Tab:AddGroup("StatusSearch")
    self.StatusesArea = self.Tab:AddGroup("AllStatuses")

    self:AddStatusSearch()

    self.AllStatuses = {}
    self:GetAllStatuses()
end

return StatusTab