---@class EquipmentSelector
---@field Container ExtuiGroup
---@field SelectorContainer ExtuiGroup
---@field QuickPickContainer ExtuiGroup
---@field SelectedEquipment table | nil
---@field OnChange function | nil
---@field ModifiedItemsPopup ExtuiPopup
---@field QuickPickItems table
EquipmentSelector = {}
EquipmentSelector.__index = EquipmentSelector

---@param parent ExtuiWindow|ExtuiChildWindow
---@param onChange function
---@return EquipmentSelector
function EquipmentSelector:New(parent, onChange)
    local instance = setmetatable({
        Container = parent:AddGroup("EquipmentSelector"),
        SelectedEquipment = nil,
        ModifiedItemsPopup = parent:AddPopup("ModifiedEquipmentPopup"),
        OnChange = onChange,
        QuickPickItems = {}
    }, EquipmentSelector)

    instance.SelectorContainer = instance.Container:AddGroup("SelectorContainer")
    instance.QuickPickContainer = instance.Container:AddGroup("QuickPickContainer")
    instance.QuickPickContainer.SameLine = true

    return instance
end

---@param equipmentData table
function EquipmentSelector:SetSelectedEquipment(equipmentData)
    if self.SelectedEquipment ~= equipmentData then
        self.SelectedEquipment = equipmentData
        if self.OnChange then
            self.OnChange(self.SelectedEquipment)
        end
        self:DrawSelector() -- Redraw to update selection visual
    end
end

function EquipmentSelector:FetchEquippedItems()
    local charUUID = UI.CharSelector and UI.CharSelector.SelectedCharacter
    if charUUID then
        SMS.FetchEquippedItems:SendToServer({ ID = USERID, character = charUUID })
    end
end

function EquipmentSelector:SetQuickPickItems(items)
    self.QuickPickItems = items or {}
    self:DrawQuickPick()
end

function EquipmentSelector:DrawSelector()
    UI.DestroyChildren(self.SelectorContainer)

    local selectedName = "None"
    local selectedIcon = "EC_Portrait_Generic"

    if self.SelectedEquipment then
        selectedName = self.SelectedEquipment.displayName or "Unknown"
        selectedIcon = self.SelectedEquipment.icon or "EC_Portrait_Generic"
    end

    local layoutTable = self.SelectorContainer:AddTable("EquipmentSelectorLayout", 2)
    layoutTable.SizingFixedSame = true
    layoutTable.NoHostExtendX = true

    local row1 = layoutTable:AddRow()
    row1:AddCell():AddText(LCL.Get("UCT_EquipmentSelector_Label", "Select Equipment to Modify:"))
    local imageCell = row1:AddCell()
    local comboImageButton = imageCell:AddImageButton("eq_select_img", selectedIcon, {100 * ViewPortScale, 100 * ViewPortScale})

    local row2 = layoutTable:AddRow()
    local buttonsCell = row2:AddCell()
    local refreshButton = buttonsCell:AddButton(LCL.Get("UCT_EquipmentSelector_Refresh", "Refresh Inventory"))
    refreshButton.OnClick = function()
        self:FetchEquippedItems()
    end
    local nameCell = row2:AddCell()
    nameCell:AddText(selectedName)

    comboImageButton.OnClick = function()
        local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
        local uuids = {}
        for uuid, _ in pairs(modifiedEquipment) do
            table.insert(uuids, uuid)
        end

        if #uuids > 0 then
            SMS.FetchModifiedItemsData:SendToServer({ ID = USERID, uuids = uuids })
        else
            self:ShowModifiedItemsPopup({})
        end
    end
end

function EquipmentSelector:DrawQuickPick()
    UI.DestroyChildren(self.QuickPickContainer)

    self.QuickPickContainer:AddSeparatorText("Quick Pick Item")

    if #self.QuickPickItems == 0 then
        self.QuickPickContainer:AddText("No items equipped.")
        return
    end

    local maxTableWidth = 4
    local tableWidth = math.min(#self.QuickPickItems, maxTableWidth)
    local t = self.QuickPickContainer:AddTable("QuickPickTable", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row = t:AddRow()

    for _, data in ipairs(self.QuickPickItems) do
        if i > 1 and (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end

        local cell = row:AddCell()
        local itemButton = cell:AddImageButton("quick_pick_btn_" .. (data.id or tostring(i)), data.icon, {60 * ViewPortScale, 60 * ViewPortScale})
        
        itemButton.OnClick = function()
            self:SetSelectedEquipment(data)
        end
        i = i + 1
    end
end

function EquipmentSelector:ShowModifiedItemsPopup(items)
    UI.DestroyChildren(self.ModifiedItemsPopup)

    self.ModifiedItemsPopup:AddSeparatorText("Modified Equipment")

    if HLP.Count(items) == 0 then
        self.ModifiedItemsPopup:AddText("No equipment has been modified yet.")
        self.ModifiedItemsPopup:Open()
        return
    end

    for uuid, data in kpairs(items) do
        local itemGroup = self.ModifiedItemsPopup:AddGroup("modified_item_" .. uuid)
        local itemButton = itemGroup:AddImageButton("mod_item_btn_" .. uuid, data.icon, {60 * ViewPortScale, 60 * ViewPortScale})
        itemGroup:AddText(data.displayName)

        itemButton.OnClick = function()
            self:SetSelectedEquipment(data)
        end
    end

    self.ModifiedItemsPopup:Open()
end

function EquipmentSelector:Draw()
    self:DrawSelector()
    self:DrawQuickPick()
end

function EquipmentSelector:Init()
    self:Draw()
    self:FetchEquippedItems()
end

return EquipmentSelector