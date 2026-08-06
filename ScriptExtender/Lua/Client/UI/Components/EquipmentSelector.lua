local UIState = Ext.Require("Client/UIState.lua")

---@class EquipmentSelector
---@field Container ExtuiGroup
---@field SelectorContainer ExtuiGroup
---@field PartyEquipmentTabBar ExtuiTabBar
---@field ModifiedItemsPopup ExtuiPopup
---@field QuickPickItems table
EquipmentSelector = {}
EquipmentSelector.__index = EquipmentSelector

---@param parent ExtuiWindow|ExtuiChildWindow
---@return EquipmentSelector
function EquipmentSelector:New(parent)
    local instance = setmetatable({
        Container = parent:AddGroup("EquipmentSelector"),
        ModifiedItemsPopup = parent:AddPopup("ModifiedEquipmentPopup"),
        QuickPickItems = {}
    }, EquipmentSelector)

    -- Use a table to create a two-column layout. This is more reliable than SameLine.
    local mainLayout = instance.Container:AddTable("MainLayout", 2)
    mainLayout.NoHostExtendX = true
    mainLayout.SizingFixedSame = true
    local mainRow = mainLayout:AddRow()

    -- Left cell for the selector
    instance.SelectorContainer = mainRow:AddCell():AddGroup("SelectorContainer")

    -- Right cell for the party equipment tabs
    instance.PartyEquipmentTabBar = mainRow:AddCell():AddTabBar("PartyEquipmentTabBar")

    return instance
end

---@param equipmentData table
function EquipmentSelector:SetSelectedEquipment(equipmentData)
    if UIState.SelectedEquipment ~= equipmentData then
        UIState:SetSelectedEquipment(equipmentData)
        self:DrawSelector() -- Redraw to update selection visual
    end
end

function EquipmentSelector:DrawSelector()
    UI_Utils.DestroyChildren(self.SelectorContainer)

    local selectedName = "None"
    local selectedIcon = "EC_Portrait_Generic"

    if UIState.SelectedEquipment then
        selectedName = UIState.SelectedEquipment.displayName or "Unknown"
        selectedIcon = UIState.SelectedEquipment.icon or "EC_Portrait_Generic"
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

function EquipmentSelector:UpdatePartyEquipment(partyItems)
    -- Destroy existing tabs within the tab bar before re-adding
    UI_Utils.DestroyChildren(self.PartyEquipmentTabBar)

    for _, member in ipairs(ItemTools.PartyMembers) do
        local memberTab = self.PartyEquipmentTabBar:AddTabItem(member.name)
        local items = partyItems[member.uuid] or {}

        if #items == 0 then
            memberTab:AddText(LCL.Get("UCT_EquipmentSelector_NoItemsEquipped", "No items equipped."))
        else
            local maxTableWidth = 8
            local tableWidth = math.min(#items, maxTableWidth)
            local t = memberTab:AddTable("QuickPickTable_" .. member.uuid, tableWidth)
            t.SizingFixedSame = true
            t.NoHostExtendX = true

            local i = 1
            local row = t:AddRow()

            for _, data in ipairs(items) do
                if i > 1 and (i - 1) % maxTableWidth == 0 then
                    row = t:AddRow()
                end

                local cell = row:AddCell()
                local itemButton = cell:AddImageButton("quick_pick_btn_" .. (data.id or tostring(i)) .. "_" .. member.uuid, data.icon, {60 * ViewPortScale, 60 * ViewPortScale})
                
                itemButton.OnClick = function()
                    self:SetSelectedEquipment(data)
                end
                i = i + 1
            end
        end
    end
end

function EquipmentSelector:ShowModifiedItemsPopup(items)
    UI_Utils.DestroyChildren(self.ModifiedItemsPopup)

    self.ModifiedItemsPopup:AddSeparatorText(LCL.Get("UCT_EquipmentSelector_ModifiedEquipment", "Modified Equipment"))

    if HLP.Count(items) == 0 then
        self.ModifiedItemsPopup:AddText(LCL.Get("UCT_EquipmentSelector_NoItemsModified", "No equipment has been modified yet."))
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
end

function EquipmentSelector:FetchEquippedItems()
    -- Fetches for the whole party, no character context needed here.
    SMS.FetchEquippedItems:SendToServer({ ID = USERID })
end

function EquipmentSelector:Init()
    self:Draw()
    self:FetchEquippedItems()
end

return EquipmentSelector