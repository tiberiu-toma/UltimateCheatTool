local Pagination = Ext.Require("Client/Pagination.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

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

        local fullName = name
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
        removeStatus.SameLine = true
        local applyToSelectedItem = popup:AddButton(LCL.Get("UCT_StatusTab_ApplyToSelectedItem", "Apply to Selected Item"))
        local removeFromSelectedItem = popup:AddButton(LCL.Get("UCT_StatusTab_RemoveFromSelectedItem", "Remove from Selected"))
        removeFromSelectedItem.SameLine = true

        local equipmentData = UI.EquipmentSelector.SelectedEquipment
        if not equipmentData then
            applyToSelectedItem.Disabled = true
            removeFromSelectedItem.Disabled = true
        else
            applyToSelectedItem.OnClick = function()
                if equipmentData and equipmentData.id then
                    local charUUID = UI.CharSelector.SelectedCharacter
                    SMS.ApplyStatusToItem:SendToServer({ character = charUUID, itemTemplateUUID = equipmentData.id, statusUUID = uuid, data = data })
                    -- Optimistically update the local data and refresh the UI
                    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
                    if not modifiedEquipment[equipmentData.id] then modifiedEquipment[equipmentData.id] = {} end
                    if not modifiedEquipment[equipmentData.id].statuses then modifiedEquipment[equipmentData.id].statuses = {} end
                    modifiedEquipment[equipmentData.id].statuses[uuid] = data
                    self:GetAppliedStatuses()
                end
            end
            removeFromSelectedItem.OnClick = function()
                if equipmentData and equipmentData.id then
                    local charUUID = UI.CharSelector.SelectedCharacter
                    SMS.RemoveStatusFromItem:SendToServer({ character = charUUID, itemTemplateUUID = equipmentData.id, statusUUID = uuid })
                    -- Optimistically update the local data and refresh the UI
                    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
                    if modifiedEquipment[equipmentData.id] and modifiedEquipment[equipmentData.id].statuses then
                        modifiedEquipment[equipmentData.id].statuses[uuid] = nil
                    end
                    self:GetAppliedStatuses()
                end
            end
        end

        data.fullName = fullName
        local statusInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, statusInfoFields)

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

---@param parent ExtuiGroup
---@param statuses table
---@param maxTableWidth number
---@param onRemove function
function StatusTab:_DrawStatusGrid(parent, statuses, maxTableWidth, onRemove)
    local total = HLP.Count(statuses)
    if total == 0 then
        return
    end

    local tableWidth = math.min(total, maxTableWidth)
    local t = parent:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row = t:AddRow()

    for uuid, data in kpairs(statuses) do
        if i > 1 and (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end

        local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
        if icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
        local fullName = HLP.GetAttr(data, "displayName")

        if not fullName then goto continue end

        local name = fullName
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local statusItem = cell:AddImageButton("", icon, {100 * ViewPortScale, 100 * ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("ManageStatus_" .. uuid)

        statusItem.OnClick = function() popup:Open() end

        data.fullName = fullName
        local infoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, infoFields)

        local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
        removeButton.OnClick = function()
            onRemove(uuid, data)
        end

        i = i + 1
        ::continue::
    end
end

function StatusTab:GetAppliedStatuses()
    UI.DestroyChildren(self.AppliedStatusesArea)

    local header = self.AppliedStatusesArea:AddCollapsingHeader("Applied Statuses")
    header:Activate()

    local layoutTable = header:AddTable("AppliedStatusesLayout", 2)
    layoutTable.SizingFixedSame = true
    layoutTable.NoHostExtendX = true

    local row = layoutTable:AddRow()
    local charStatusesCell = row:AddCell()
    local itemStatusesCell = row:AddCell()

    -- Column 1: Character Statuses
    charStatusesCell:AddSeparatorText("On Character")
    local charUUID = UI.CharSelector and UI.CharSelector.SelectedCharacter
    if not charUUID then
        charStatusesCell:AddText("Select a character.")
    else
        local appliedForChar = self.AppliedStatuses[charUUID] or {}
        if HLP.Count(appliedForChar) == 0 then
            charStatusesCell:AddText("No custom statuses.")
        else
            self:_DrawStatusGrid(charStatusesCell, appliedForChar, 3, function(uuid, data)
                local charUUID = UI.CharSelector.SelectedCharacter
                SMS.ApplyStatus:SendToServer({ character = charUUID, uuid = uuid, remove = 1 })
                if self.AppliedStatuses[charUUID] then self.AppliedStatuses[charUUID][uuid] = nil end
                self:GetAppliedStatuses()
            end)
        end
    end

    -- Column 2: Item Statuses
    itemStatusesCell:AddSeparatorText("On Selected Item")
    local equipmentData = UI.EquipmentSelector.SelectedEquipment
    if not equipmentData then
        itemStatusesCell:AddText("No item selected.")
    else
        local itemTemplateUUID = equipmentData.id
        local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
        local itemMods = modifiedEquipment[itemTemplateUUID]
        local itemStatuses = itemMods and itemMods.statuses

        if not itemStatuses or HLP.Count(itemStatuses) == 0 then
            itemStatusesCell:AddText("No custom statuses.")
        else
            self:_DrawStatusGrid(itemStatusesCell, itemStatuses, 3, function(uuid, data)
                local charUUID = UI.CharSelector.SelectedCharacter
                SMS.RemoveStatusFromItem:SendToServer({ character = charUUID, itemTemplateUUID = itemTemplateUUID, statusUUID = uuid })
                self:GetAppliedStatuses()
            end)
        end
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