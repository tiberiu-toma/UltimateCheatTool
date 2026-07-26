---@class EquipmentTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field EquipmentItems table
---@field ResultCount int
---@field EquipmentArea ExtuiCollapsingHeader
---@field EquipmentSearch ExtuiGroup
---@field AmountOptions table
EquipmentTab = {}
EquipmentTab.__index = EquipmentTab

---@param holder ExtuiTabBar
function EquipmentTab:GetEquipmentItems(search)    
    search = search or ""
    SMS.FetchEquipment:SendToServer({ ID=USERID, search=search })
end

function EquipmentTab:New(holder)
    if UI.EquipmentTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Equipment")),
        EquipmentItems = {},
        ResultCount = 0,
        
        AmountOptions = {1, 2, 5, 10, 99}
    }, EquipmentTab)
    return instance
end

function EquipmentTab:SetEquipment(items)
    UI.DestroyChildren(self.EquipmentArea)

    self.EquipmentItems = items
    self.ResultCount = HLP.Count(items)

    local shownCount = HLP.Count(self.EquipmentItems)

    if shownCount == 0 then
        self.EquipmentArea:AddText("No items found.")
        return
    end

    local maxTableWidth = 4
    local tableWidth = math.min(shownCount, maxTableWidth) 

    self.EquipmentArea:AddText("Showing " .. shownCount .. " items (max: 50)")

    local t = self.EquipmentArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1

    local row = t:AddRow()

    for uuid,data in kpairs(self.EquipmentItems) do
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
        local equipmentItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddItem")

        equipmentItem.OnClick = function()
            popup:Open()
        end

        for _,num in kpairs(self.AmountOptions) do
            local selectEquipment = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn") .. " " .. num)

            selectEquipment.OnClick = function()
                SMS.SpawnTemplate:SendToServer({ uuid=uuid, amount=num })
            end
        end

        i = i + 1

        ::continue::
    end

    --print(i .. " total cells added")
end

function EquipmentTab:AddEquipmentSearch()
    UI.DestroyChildren(self.EquipmentSearch)

    local sep = self.EquipmentSearch:AddSeparatorText(LCL.Get("hbea4aec9a88b4a34b615f347cb48d3ed1", "Search Equipment:"))

    local search = self.EquipmentSearch:AddInputText("", "")
    local btn = self.EquipmentSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        local txt = search.Text 

        self:GetEquipmentItems(txt)
    end
end

function EquipmentTab:Init()
    self.EquipmentSearch = self.Tab:AddGroup("EquipmentSearch")
    self.EquipmentArea = self.Tab:AddGroup("EquipmentItems")

    self:AddEquipmentSearch()

    self.EquipmentItems = {}
    self:GetEquipmentItems()
end

return EquipmentTab

--[[

function EquipmentTab:GetDisplayNames(all)
    local data = {}
    local items = {}

    local total = 0

    for uuid,entry in kpairs(all) do 
        total = total + 1

        local id = HLP.GetAttr(entry, "id")
        local name = HLP.GetAttr(entry, "name")
        local icon = HLP.GetAttr(entry, "icon")
        local dname = HLP.GetAttr(entry, "dname")

        if dname and name then
            local displayName = LCL.Get(dname, name)
            
            items[uuid] = entry
            data[uuid] = displayName
            items[uuid]["dname"] = displayName
        end 
    end


    self.EquipmentNames = data
end]]