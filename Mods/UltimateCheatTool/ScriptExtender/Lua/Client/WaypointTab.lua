local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class WaypointTab : BaseTab
WaypointTab = {}
setmetatable(WaypointTab, { __index = BaseTab })
WaypointTab.__index = WaypointTab

function WaypointTab:New(holder)
    if UI.WaypointTab then return end 

    local config = {
        tabName = "Waypoints",
        idPrefix = "Waypoint",
        fetchMessage = SMS.FetchWaypoints,
        searchLabel = "Search Waypoints:",
        noItemsText = "No waypoints found.",
        maxTableWidth = 5
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, WaypointTab)
    return instance
end

function WaypointTab:DrawGrid()
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
        local name = HLP.GetAttr(data, "name")
        local trigger = HLP.GetAttr(data, "trigger")

        if not name then goto continue end

        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        icon = "EC_Portrait_Generic"
        local cell = row:AddCell()
        local waypointItem = cell:AddImageButton("##Waypoint" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddItem" .. uuid)

        waypointItem.OnClick = function()
            popup:Open()
        end

        local selectWaypoint = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb79", "Teleport"))

        local waypointInfoFields = {
            { key = "id", label = "ID" },
            { key = "name", label = "Name" },
            { key = "trigger", label = "Trigger" },
            { key = "pos", label = "Position", formatter = function(pos)
                if not pos then return "N/A" end
                return string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.x or 0, pos.y or 0, pos.z or 0)
            end },
        }
        InfoPopup:AddInfo(popup, data, waypointInfoFields)

        selectWaypoint.OnClick = function()
            if trigger then
                SMS.TeleportToWaypoint:SendToServer({ data=trigger })
            else
                Ext.Utils.PrintError("Waypoint " .. name .. " has no trigger.")
            end
        end

        i = i + 1

        ::continue::
    end
end

return WaypointTab