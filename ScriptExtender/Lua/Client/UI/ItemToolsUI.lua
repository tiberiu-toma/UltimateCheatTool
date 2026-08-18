local UI_Events = Ext.Require("Client/UI/UIEvents.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local EquipmentSelector = Ext.Require("Client/UI/Components/EquipmentSelector.lua")
local EquipmentTab = Ext.Require("Client/UI/Tabs/EquipmentTab.lua")
local ConsumableTab = Ext.Require("Client/UI/Tabs/ConsumableTab.lua")
local PassiveTab = Ext.Require("Client/UI/Tabs/PassiveTab.lua")
local OtherItemTab = Ext.Require("Client/UI/Tabs/OtherItemTab.lua")
local StatusTab = Ext.Require("Client/UI/Tabs/StatusTab.lua")
local DamageTab = Ext.Require("Client/UI/Tabs/DamageTab.lua")

---@class ItemToolsUI
---@field Ready boolean
---@field Window ExtuiChildWindow
---@field Settings table<string, any>
---@field HotKeys table<string, any>
---@field EquipmentSelector EquipmentSelector
---@field TabBar ExtuiTabBar
---@field EquipmentTab EquipmentTab
---@field ConsumableTab ConsumableTab
---@field OtherItemTab OtherItemTab
---@field PassiveTab PassiveTab
---@field StatusTab StatusTab
---@field DamageTab DamageTab
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
        if self.PassiveTab and self.PassiveTab.Tab.Visible then
            self.PassiveTab:GetAppliedModifications()
            -- Re-render the main grid to update button states without a server call
            self.PassiveTab:SetData({
                data = self.PassiveTab.Items,
                totalItems = self.PassiveTab.TotalItems,
                totalPages = self.PassiveTab.TotalPages,
                currentPage = self.PassiveTab.CurrentPage
            })
        end
        if self.StatusTab and self.StatusTab.Tab.Visible then
            self.StatusTab:GetAppliedModifications()
            -- Re-render the main grid to update button states without a server call
            self.StatusTab:SetData({
                data = self.StatusTab.Items,
                totalItems = self.StatusTab.TotalItems,
                totalPages = self.StatusTab.TotalPages,
                currentPage = self.StatusTab.CurrentPage
            })
        end
        if self.DamageTab and self.DamageTab.Tab.Visible then
            self.DamageTab:Draw() -- Redraw builder UI
            self.DamageTab:GetAddedDamage() -- Redraw the list of applied boosts
        end
    end)

    self.TabBar = self.Window:AddTabBar("UCT_ItemTabBar")

    self.EquipmentTab = EquipmentTab:New(self.TabBar)
    self.ConsumableTab = ConsumableTab:New(self.TabBar)
    self.OtherItemTab = OtherItemTab:New(self.TabBar)
    self.DamageTab = DamageTab:New(self.TabBar)
    self.PassiveTab = PassiveTab:New(self.TabBar, "ItemTools") -- Add PassiveTab to ItemTools
    self.StatusTab = StatusTab:New(self.TabBar, "ItemTools") -- Add StatusTab to ItemTools

    self.EquipmentTab:Init()
    self.ConsumableTab:Init()
    self.OtherItemTab:Init()
    self.DamageTab:Init()
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