local UI_Events = Ext.Require("Client/UI_Events.lua")

---@class UIState
--- Manages shared state between decoupled UI components.
local UIState = {
    SelectedCharacter = nil,
    SelectedEquipment = nil,
}

function UIState:SetSelectedCharacter(charUUID)
    if self.SelectedCharacter ~= charUUID then
        self.SelectedCharacter = charUUID
        UI_Events:Publish("CharacterChanged", charUUID)
    end
end

function UIState:SetSelectedEquipment(eqData)
    if self.SelectedEquipment ~= eqData then
        self.SelectedEquipment = eqData
        UI_Events:Publish("EquipmentChanged", eqData)
    end
end

return UIState