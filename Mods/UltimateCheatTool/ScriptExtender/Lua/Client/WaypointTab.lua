---@class WaypointTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field WaypointItems table
---@field ResultCount int
---@field WaypointArea ExtuiCollapsingHeader
---@field WaypointSearch ExtuiGroup
---@field AmountOptions table
WaypointTab = {}
WaypointTab.__index = WaypointTab

---@param holder ExtuiTabBar
function WaypointTab:GetWaypointItems(search)    
    search = search or ""
    SMS.FetchWaypoints:SendToServer({ ID=USERID, search=search })
end

function WaypointTab:New(holder)
    if UI.WaypointTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Waypoints")),
        WaypointItems = {},
        ResultCount = 0,
        
        AmountOptions = {1, 2, 5, 10, 99}
    }, WaypointTab)
    return instance
end

function WaypointTab:SetWaypoints(items)
    UI.DestroyChildren(self.WaypointArea)

    self.WaypointItems = items
    self.ResultCount = HLP.Count(items)

    local shownCount = HLP.Count(self.WaypointItems)

    if shownCount == 0 then
        self.WaypointArea:AddText("No items found.")
        return
    end

    local maxTableWidth = 4
    local tableWidth = math.min(shownCount, maxTableWidth) 

    self.WaypointArea:AddText("Showing " .. shownCount .. " items (max: 50)")

    local t = self.WaypointArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.WaypointItems) do
        if i % maxTableWidth == 1 then
            row = t:AddRow()
        end
        
        local uuid = HLP.GetAttr(data, "id")
        local icon = HLP.GetAttr(data, "icon")
        local name = HLP.GetAttr(data, "name")
        local trigger = HLP.GetAttr(data, "trigger")

        if not name then
            --print("Skipping invalid entry:", uuid)
            goto continue
        end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        icon = "EC_Portrait_Generic"
        local cell = row:AddCell()
        local WaypointItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddItem")

        WaypointItem.OnClick = function()
            popup:Open()
        end

        local selectWaypoint = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb79", "Teleport"))

        selectWaypoint.OnClick = function()
            SMS.TeleportToWaypoint:SendToServer({ data=trigger })
        end

        i = i + 1

        ::continue::
    end

    --print(i .. " total cells added")
end

function WaypointTab:AddWaypointSearch()
    UI.DestroyChildren(self.WaypointSearch)

    local sep = self.WaypointSearch:AddSeparatorText(LCL.Get("hbea4aec9a88b4a34b615f347cb48d3ed1", "Search Waypoint:"))

    local search = self.WaypointSearch:AddInputText("", "")
    local btn = self.WaypointSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        local txt = search.Text 

        self:GetWaypointItems(txt)
    end
end

function WaypointTab:Init()
    self.WaypointSearch = self.Tab:AddGroup("WaypointSearch")
    self.WaypointArea = self.Tab:AddGroup("WaypointItems")

    self:AddWaypointSearch()

    self.WaypointItems = {}
    self:GetWaypointItems()
end

return WaypointTab