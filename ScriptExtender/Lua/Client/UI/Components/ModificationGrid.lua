---@class ModificationGrid
--- A reusable component for displaying a grid of modifications applied to a context (like a character or item).
local ModificationGrid = {}
ModificationGrid.__index = ModificationGrid

---@param parent ExtuiGroup The parent UI element to draw into.
---@param config table Configuration for the grid.
---@return ModificationGrid
function ModificationGrid:New(parent, config)
    local instance = setmetatable({
        Parent = parent,
        Config = config or {},
    }, ModificationGrid)
    return instance
end

--- Draws the grid of added items.
---@param data table The data to display, keyed by a unique ID.
function ModificationGrid:Draw(data)
    UI_Utils.DestroyChildren(self.Parent)

    local totalAdded = HLP.Count(data)
    if totalAdded == 0 then
        self.Parent:AddText(self.Config.noItemsText or "No items added.")
        return
    end

    local maxTableWidth = self.Config.maxTableWidth or 3
    local tableWidth = math.min(totalAdded, maxTableWidth)
    
    local header = self.Parent:AddCollapsingHeader(self.Config.headerText or "Applied Modifications")

    local t = header:AddTable("ModificationGrid_" .. (self.Config.idPrefix or ""), tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row
    local drawnCount = 0
    local maxDrawn = 50 -- Performance cap

    for uuid, itemData in kpairs(data) do
        if drawnCount >= maxDrawn then
            header:AddText("...and more (list truncated for performance).")
            break
        end

        if (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end

        local cell = row:AddCell()
        
        self.Config.renderItem(cell, uuid, itemData)

        i = i + 1
        drawnCount = drawnCount + 1
    end
end

return ModificationGrid