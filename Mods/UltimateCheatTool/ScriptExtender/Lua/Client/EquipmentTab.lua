local Pagination = Ext.Require("Client/Pagination.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class EquipmentTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field EquipmentItems table
---@field ResultCount int
---@field EquipmentArea ExtuiCollapsingHeader
---@field EquipmentSearch ExtuiGroup
---@field AmountOptions table
---@field CurrentPage number
---@field TotalPages number
---@field TotalItems number
---@field SearchText string
---@field PaginationAreaTop ExtuiGroup
---@field PaginationAreaBottom ExtuiGroup
EquipmentTab = {}
EquipmentTab.__index = EquipmentTab

---@param holder ExtuiTabBar
function EquipmentTab:GetEquipmentItems(page)
    self.CurrentPage = page or 1
    SMS.FetchEquipment:SendToServer({ ID=USERID, search=self.SearchText, page=self.CurrentPage })
end

function EquipmentTab:New(holder)
    if UI.EquipmentTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Equipment")),
        EquipmentItems = {},
        ResultCount = 0,
        AmountOptions = {1, 2, 5, 10, 99},
        CurrentPage = 1,
        TotalPages = 1,
        TotalItems = 0,
        SearchText = ""
    }, EquipmentTab)
    return instance
end

function EquipmentTab:SetEquipment(payload)
    UI.DestroyChildren(self.EquipmentArea)
    UI.DestroyChildren(self.PaginationAreaTop)
    UI.DestroyChildren(self.PaginationAreaBottom)

    local items = payload.data
    self.EquipmentItems = items
    self.ResultCount = HLP.Count(items)

    self.TotalItems = payload.totalItems or 0
    self.TotalPages = payload.totalPages or 1
    self.CurrentPage = payload.currentPage or 1

    if self.TotalItems == 0 then
        self.EquipmentArea:AddText("No items found.")
        return
    end

    local shownCount = HLP.Count(self.EquipmentItems)
    local maxTableWidth = 5
    local tableWidth = math.min(shownCount, maxTableWidth) 

    Pagination:CreateControls({
        parent = self.PaginationAreaTop,
        idSuffix = "Top",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetEquipmentItems(page) end
    })

    self.EquipmentArea:AddText("Showing " .. shownCount .. " of " .. self.TotalItems .. " items.")
    
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

        local rarity = HLP.GetAttr(data, "rarity", nil)
        local armorClass = HLP.GetAttr(data, "armorClass", nil)
        local armorType = HLP.GetAttr(data, "armorType", nil)
        local slot = HLP.GetAttr(data, "slot", nil)
        local defaultBoosts = HLP.GetAttr(data, "defaultBoosts", nil)
        local boosts = HLP.GetAttr(data, "boosts", nil)
        local boostsOnEquipMainHand = HLP.GetAttr(data, "boostsOnEquipMainHand", nil)
        local boostsOnEquipOffHand = HLP.GetAttr(data, "boostsOnEquipOffHand", nil)
        local passivesOnEquip = HLP.GetAttr(data, "passivesOnEquip", nil)

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
        local equipmentItem = cell:AddImageButton("",icon, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddItem")

        equipmentItem.OnClick = function()
            popup:Open()
        end
        
        for _,num in kpairs(self.AmountOptions) do
            local selectEquipment = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn") .. " " .. num)
            selectEquipment.SameLine = true

            selectEquipment.OnClick = function()
                local charUUID = UI.CharSelector.SelectedCharacter
                SMS.SpawnTemplate:SendToServer({ character = charUUID, uuid=uuid, amount=num })
            end
        end

        local setAsSelectedBtn = popup:AddButton("Set as Selected Equipment")
        setAsSelectedBtn.OnClick = function()
            if UI and UI.EquipmentSelector then
                UI.EquipmentSelector:SetSelectedEquipment(data)
            end
        end

        data.fullName = fullName
        local equipmentInfoFields = {
            { key = "id", label = "ID", sameLine = false },
            { key = "fullName", label = "Name" },
            { key = "rarity", label = "Rarity" },
            { key = "armorClass", label = "Armor Class" },
            { key = "armorType", label = "Armor Type" },
            { key = "slot", label = "Slot" },
            { key = "defaultBoosts", label = "Default Boosts", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "boosts", label = "Boosts", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "boostsOnEquipMainHand", label = "Boosts on Equip (Main Hand)", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "boostsOnEquipOffHand", label = "Boosts on Equip (Off Hand)", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "passivesOnEquip", label = "Passives on Equip", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "modName", label = "Mod Name" },
        }
        InfoPopup:AddInfo(popup, data, equipmentInfoFields)

        i = i + 1

        ::continue::
    end

    Pagination:CreateControls({
        parent = self.PaginationAreaBottom,
        idSuffix = "Bottom",
        currentPage = self.CurrentPage,
        totalPages = self.TotalPages,
        onPageChange = function(page) self:GetEquipmentItems(page) end
    })
end

function EquipmentTab:AddEquipmentSearch()
    UI.DestroyChildren(self.EquipmentSearch)

    local sep = self.EquipmentSearch:AddSeparatorText(LCL.Get("hbea4aec9a88b4a34b615f347cb48d3ed1", "Search Equipment:"))

    local search = self.EquipmentSearch:AddInputText("", "")
    local btn = self.EquipmentSearch:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb76", "Search"))

    btn.OnClick = function()
        self.SearchText = search.Text 
        self:GetEquipmentItems(1)
    end

    local spawnAllBtn = self.EquipmentSearch:AddButton(LCL.Get("", "Spawn All (Non-Story)"))
    spawnAllBtn.OnClick = function()
        local charUUID = UI.CharSelector.SelectedCharacter
        SMS.SpawnAllEquipment:SendToServer({ ID = charUUID })
    end
end

function EquipmentTab:Init()
    self.EquipmentSearch = self.Tab:AddGroup("EquipmentSearch")
    self.PaginationAreaTop = self.Tab:AddGroup("PaginationAreaTop")
    self.EquipmentArea = self.Tab:AddGroup("EquipmentItems")
    self.PaginationAreaBottom = self.Tab:AddGroup("PaginationAreaBottom")

    self:AddEquipmentSearch()

    self.EquipmentItems = {}
    self:GetEquipmentItems(1)
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