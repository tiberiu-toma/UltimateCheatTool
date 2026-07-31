---@class EquipmentSelector
---@field Container ExtuiGroup
---@field SelectedEquipment table | nil
---@field OnChange function | nil
---@field ModifiedItemsPopup ExtuiPopup
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
    }, EquipmentSelector)
    return instance
end

---@param equipmentData table
function EquipmentSelector:SetSelectedEquipment(equipmentData)
    if self.SelectedEquipment ~= equipmentData then
        self.SelectedEquipment = equipmentData
        if self.OnChange then
            self.OnChange(self.SelectedEquipment)
        end
        self:Draw() -- Redraw to update selection visual
    end
end

function EquipmentSelector:Draw()
    UI.DestroyChildren(self.Container)

    local selectedName = "None"
    local selectedIcon = "EC_Portrait_Generic"

    if self.SelectedEquipment then
        selectedName = self.SelectedEquipment.displayName or "Unknown"
        selectedIcon = self.SelectedEquipment.icon or "EC_Portrait_Generic"
    end

    self.Container:AddText("Select Equipment to Modify:")

    local comboImageButton = self.Container:AddImageButton("eq_select_img", selectedIcon, {100 * ViewPortScale, 100 * ViewPortScale})

    self.Container:AddText(selectedName)

    -- Clicking the image redirects to the Equipment tab.
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

        if UI and UI.TabBar and UI.EquipmentTab then
            UI.EquipmentTab.Tab:Activate()
        end
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
            -- self.ModifiedItemsPopup:Close()
        end
    end

    self.ModifiedItemsPopup:Open()
end

function EquipmentSelector:Init()
    self:Draw()
end

return EquipmentSelector