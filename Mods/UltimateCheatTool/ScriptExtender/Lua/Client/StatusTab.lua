local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class StatusTab : BaseTab
---@field AppliedStatuses table
---@field AppliedStatusesArea ExtuiGroup
StatusTab = {}
setmetatable(StatusTab, { __index = BaseTab })
StatusTab.__index = StatusTab

function StatusTab:New(holder)
    if UI.StatusTab then return end

    local config = {
        tabName = "Statuses",
        idPrefix = "Status",
        fetchMessage = SMS.FetchStatuses,
        searchLabel = "Search Statuses:",
        noItemsText = "No statuses found.",
        maxTableWidth = 5
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, StatusTab) -- Re-set metatable to the child class
    instance.AppliedStatuses = {}
    return instance
end

function StatusTab:Init()
    self.AppliedStatusesArea = self.Tab:AddGroup("AppliedStatuses")
    self:GetAppliedStatuses()

    -- This will create the search, pagination, and main areas and fetch the first page of all statuses
    BaseTab.Init(self)
end

function StatusTab:DrawGrid()
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
        local statusItem = cell:AddImageButton("##Status" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddStatus" .. uuid)

        statusItem.OnClick = function()
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
                    self:GetAppliedStatuses(true)
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
                    self:GetAppliedStatuses(true)
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
            self:GetAppliedStatuses(true)
        end

        applyStatus.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.ApplyStatus:SendToServer({ character = charUUID, uuid=uuid, amount=1, data=data })
            if not self.AppliedStatuses[charUUID] then self.AppliedStatuses[charUUID] = {} end
            self.AppliedStatuses[charUUID][uuid] = data
            self:GetAppliedStatuses(true)
        end

        i = i + 1

        ::continue::
    end
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
    local row
    local drawnCount = 0
    local maxDrawn = 50 -- Performance cap

    for uuid, data in kpairs(statuses) do
        if drawnCount >= maxDrawn then
            parent:AddText("...and more (list truncated for performance).")
            break
        end

        if (i - 1) % maxTableWidth == 0 then
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
        local statusItem = cell:AddImageButton("##StatusGrid" .. uuid, icon, {100 * ViewPortScale, 100 * ViewPortScale})
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
        drawnCount = drawnCount + 1
        ::continue::
    end
end

function StatusTab:GetAppliedStatuses(noRefetch)
    if not noRefetch then
        self.AppliedStatuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
    end

    UI.DestroyChildren(self.AppliedStatusesArea)

    local header = self.AppliedStatusesArea:AddCollapsingHeader("Applied Statuses")

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
                self:GetAppliedStatuses(true)
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
                -- Optimistically update the client-side variable to avoid UI lag
                local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment
                if modifiedEquipment and modifiedEquipment[itemTemplateUUID] and modifiedEquipment[itemTemplateUUID].statuses then
                    modifiedEquipment[itemTemplateUUID].statuses[uuid] = nil
                    if HLP.Count(modifiedEquipment[itemTemplateUUID].statuses) == 0 then modifiedEquipment[itemTemplateUUID].statuses = nil end
                    if HLP.Count(modifiedEquipment[itemTemplateUUID]) == 0 then modifiedEquipment[itemTemplateUUID] = nil end
                    -- Set the modified table back to the variable
                    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
                end
                self:GetAppliedStatuses(true)
            end)
        end
    end
end

return StatusTab