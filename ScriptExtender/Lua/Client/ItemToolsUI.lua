local UI_Events = Ext.Require("Client/UI_Events.lua")
local UIState = Ext.Require("Client/UIState.lua")
local EquipmentSelector = Ext.Require("Client/EquipmentSelector.lua")
local EquipmentTab = Ext.Require("Client/EquipmentTab.lua")
local ConsumableTab = Ext.Require("Client/ConsumableTab.lua")
local PassiveTab = Ext.Require("Client/PassiveTab.lua")
local StatusTab = Ext.Require("Client/StatusTab.lua")

---@class ItemToolsUI
---@field Ready boolean
---@field Window ExtuiChildWindow
---@field Settings table<string, any>
---@field HotKeys table<string, any>
---@field EquipmentSelector EquipmentSelector
---@field TabBar ExtuiTabBar
---@field EquipmentTab EquipmentTab
---@field ConsumableTab ConsumableTab
---@field PartyMembers table
ItemToolsUI = {}
ItemToolsUI.__index = ItemToolsUI

function ItemToolsUI:New(mcm)
    local window
    local instance = setmetatable({
        Window = nil, -- Will be set below
        Settings = {},
        HotKeys = {},
        Ready = false,
        PartyMembers = {},
    }, ItemToolsUI)

    if mcm then
        instance.Window = mcm:AddChildWindow("UltimateCheatTool_ItemTools")
    else
        -- For standalone mod, create a regular window
        instance.Window = Ext.IMGUI.NewWindow("Ultimate Cheat Tool (Item Tools)")
        instance.Window.Open = true
    end
    return instance
end

function ItemToolsUI:Initialize()
    if self.Ready then return end

    self.EquipmentSelector = EquipmentSelector:New(self.Window)
    self.EquipmentSelector.Container.SameLine = true
    self.EquipmentSelector:Init()

    UI_Events:Subscribe("CharacterChanged", function(charUUID)
        -- When the main character context changes, re-fetch all party equipment
        self.EquipmentSelector:FetchEquippedItems()
    end)

    -- Subscribe to events
    UI_Events:Subscribe("EquipmentChanged", function(eqData)
        -- This function will be called when the equipment selection changes.
        -- Let's force a redraw of the added/applied sections for relevant tabs.
        if self.PassiveTab and self.PassiveTab.Tab.Visible then self.PassiveTab:GetAddedPassives() end
        if self.StatusTab and self.StatusTab.Tab.Visible then self.StatusTab:GetAppliedStatuses() end
    end)

    self.TabBar = self.Window:AddTabBar("UCT_ItemTabBar")

    self.EquipmentTab = EquipmentTab:New(self.TabBar)
    self.ConsumableTab = ConsumableTab:New(self.TabBar)
    self.PassiveTab = PassiveTab:New(self.TabBar, "ItemTools") -- Add PassiveTab to ItemTools
    self.StatusTab = StatusTab:New(self.TabBar, "ItemTools") -- Add StatusTab to ItemTools

    self.EquipmentTab:Init()
    self.ConsumableTab:Init()
    self.PassiveTab:Init() -- Initialize ItemTools' PassiveTab
    self.StatusTab:Init() -- Initialize ItemTools' StatusTab
    self.Ready = true
end

function ItemToolsUI:HideWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:CloseMCMWindow()
    else
        if self.Window then
            self.Window.Open = false
        end
    end
end

function ItemToolsUI:ShowWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:OpenMCMWindow()
    else
        if self.Window then
            self.Window.Open = true
        end
        self.EquipmentSelector:FetchEquippedItems() -- Refresh quick picks when UI is opened
    end
end

return ItemToolsUI