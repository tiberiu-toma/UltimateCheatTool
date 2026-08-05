USERID = nil
ViewPort = Ext.IMGUI.GetViewportSize()
ViewPortScale = Ext.IMGUI.GetViewportSize()[2] / 1440
MCMActive = Mods and Mods.BG3MCM

-- Global instances for CharacterTools and ItemTools UIs
CharacterTools = nil
ItemTools = nil

local BaseTab = Ext.Require("Client/BaseTab.lua")
local EquipmentTab = Ext.Require("Client/EquipmentTab.lua")
local NPCTab = Ext.Require("Client/NPCTab.lua")
local SpellTab = Ext.Require("Client/SpellTab.lua")
local PassiveTab = Ext.Require("Client/PassiveTab.lua")
local StatusTab = Ext.Require("Client/StatusTab.lua")
local ConsumableTab = Ext.Require("Client/ConsumableTab.lua")
local WaypointTab = Ext.Require("Client/WaypointTab.lua")
local RecruitTab = Ext.Require("Client/RecruitTab.lua")
local TagTab = Ext.Require("Client/TagTab.lua")
local CharacterSelector = Ext.Require("Client/CharacterSelector.lua")
local EquipmentSelector = Ext.Require("Client/EquipmentSelector.lua")
local GenericTab = Ext.Require("Client/GenericTab.lua")
local ResetTab = Ext.Require("Client/ResetTab.lua")

--------------------------------------------------
--------------------------------------------------
-- Common UI Utility Functions
UI_Utils = {}

function UI_Utils.DestroyChildren(obj)
    if obj == nil then
        return
    end
    if HLP.GetAttr(obj, "Children") and #obj.Children > 0 then
        for _,child in pairs(obj.Children) do
            child:Destroy()
        end
    end
end

function UI_Utils.CenterObjectH(parent, objDef)
    if not objDef or not parent then return end

    local table = parent:AddTable("CenteringTable", 3)
    table.SizingFixedSame = true
    table.NoHostExtendX = false
    local row = table:AddRow()
    local leftCell = row:AddCell()
    local centerCell = row:AddCell()
    local rightCell = row:AddCell()
    return objDef(centerCell)
end

function UI_Utils.CenterObjectV(parent, objDef)
    if not objDef or not parent then return end

    local table = parent:AddTable("CenteringTable", 1)
    table.SizingFixedSame = true
    table.NoHostExtendX = false
    local row1 = table:AddRow()
    local row2 = table:AddRow()
    local row3 = table:AddRow()
    local topCell = row1:AddCell()
    local centerCell = row2:AddCell()
    local bottomCell = row3:AddCell()
    return objDef(centerCell)
end

---Set tab visibility from LocalSettings default fallback
---@param tab table The tab object with a Tab property
---@param settingsKey string The LocalSettings key (e.g., "Tab_Debug")
---@param defaultVisible boolean The default visibility if not in LocalSettings
function UI_Utils.SetDefaultTabVisibility(tab, settingsKey, defaultVisible)
    local visibilitySettings = LocalSettings:GetOr({ Visible = defaultVisible }, settingsKey)
    if type(visibilitySettings) ~= "table" then
        visibilitySettings = { Visible = defaultVisible }
        LocalSettings:AddOrChange(settingsKey, visibilitySettings)
    end
    tab.Tab.Visible = visibilitySettings.Visible
end

-- Character Tools UI Class
---@class CharacterToolsUI
---@field Ready boolean
---@field Window ExtuiChildWindow
---@field Settings table<string, any>
---@field HotKeys table<string, any>
---@field CharSelector CharacterSelector
---@field TabBar ExtuiTabBar
---@field GenericTab GenericTab
---@field RecruitTab RecruitTab
---@field NPCTab NPCTab
---@field TagTab TagTab
---@field SpellTab SpellTab
---@field PassiveTab PassiveTab
---@field StatusTab StatusTab
---@field WaypointTab WaypointTab
---@field ResetTab ResetTab
CharacterToolsUI = {}
CharacterToolsUI.__index = CharacterToolsUI

function CharacterToolsUI:New(mcm)
    local window
    local instance = setmetatable({
        Window = nil, -- Will be set below
        Settings = {},
        HotKeys = {},
        Ready = false,
    }, CharacterToolsUI)

    if mcm then
        instance.Window = mcm:AddChildWindow("UltimateCheatTool_CharacterTools")
    else
        -- For standalone mod, create a regular window
        instance.Window = Ext.IMGUI.NewWindow("Ultimate Cheat Tool (Character Tools)")
        instance.Window.Open = true
    end
    return instance
end

function CharacterToolsUI:Initialize()
    if self.Ready then return end

    USERID = _C().Uuid.EntityUuid -- USERID is character-centric

    self.CharSelector = CharacterSelector:New(self.Window, function(charUUID) self:OnCharacterChange(charUUID) end)
    self.CharSelector:Init()

    self.TabBar = self.Window:AddTabBar("UCT_CharacterTabBar")

    self.GenericTab = GenericTab:New(self.TabBar)
    self.RecruitTab = RecruitTab:New(self.TabBar)
    self.NPCTab = NPCTab:New(self.TabBar)
    self.PassiveTab = PassiveTab:New(self.TabBar, "CharacterTools") -- Add PassiveTab to CharacterTools
    self.StatusTab = StatusTab:New(self.TabBar, "CharacterTools") -- Add StatusTab to CharacterTools
    self.TagTab = TagTab:New(self.TabBar)
    self.SpellTab = SpellTab:New(self.TabBar)
    self.WaypointTab = WaypointTab:New(self.TabBar)
    self.ResetTab = ResetTab:New(self.TabBar)

    self.GenericTab:Init()
    self.RecruitTab:Init()
    self.NPCTab:Init()
    self.PassiveTab:Init() -- Initialize CharacterTools' PassiveTab
    self.StatusTab:Init() -- Initialize CharacterTools' StatusTab
    self.TagTab:Init()
    self.SpellTab:Init()
    self.WaypointTab:Init()
    self.ResetTab:Init()

    self.Ready = true
end

function CharacterToolsUI:OnCharacterChange(charUUID)
    -- This function will be called when the character selection changes.
    -- Let's force a redraw of the added/applied sections for relevant tabs.
    if ItemTools and ItemTools.EquipmentSelector then
        ItemTools.EquipmentSelector:SetSelectedEquipment(nil) -- Clear selected equipment when character changes in CharacterTools
        ItemTools.EquipmentSelector:FetchEquippedItems() -- Refresh quick picks for ItemTools
    end

    -- Refresh tabs in CharacterTools
    if self.PassiveTab and self.PassiveTab.Tab.Visible then self.PassiveTab:GetAddedPassives() end -- Refresh CharacterTools' PassiveTab
    if self.SpellTab and self.SpellTab.Tab.Visible then self.SpellTab:GetLearnedSpells() end
    if self.TagTab and self.TagTab.Tab.Visible then self.TagTab:GetAppliedTags() end
    if self.StatusTab and self.StatusTab.Tab.Visible then self.StatusTab:GetAppliedStatuses() end -- Refresh CharacterTools' StatusTab

    -- Also refresh relevant tabs in ItemTools since character change affects them
    if ItemTools and ItemTools.PassiveTab and ItemTools.PassiveTab.Tab.Visible then ItemTools.PassiveTab:GetAddedPassives() end
    if ItemTools and ItemTools.StatusTab and ItemTools.StatusTab.Tab.Visible then ItemTools.StatusTab:GetAppliedStatuses() end
end

function CharacterToolsUI:HideWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:CloseMCMWindow()
    else
        if self.Window then
            self.Window.Open = false
        end
    end
    -- if self.SceneControl and self.SceneControl.ActiveSceneControls then
    --     for _,sceneControl in pairs(self.SceneControl.ActiveSceneControls) do
    --         sceneControl.TempClosed = true
    --         sceneControl.Window.Open = false
    --     end
    -- end
end

function CharacterToolsUI:ShowWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:OpenMCMWindow()
    else
        if self.Window then
            self.Window.Open = true
        end
    end
end

-- Item Tools UI Class
---@class ItemToolsUI
---@field Ready boolean
---@field Window ExtuiChildWindow
---@field Settings table<string, any>
---@field HotKeys table<string, any>
---@field EquipmentSelector EquipmentSelector
---@field TabBar ExtuiTabBar
---@field EquipmentTab EquipmentTab
---@field ConsumableTab ConsumableTab
ItemToolsUI = {}
ItemToolsUI.__index = ItemToolsUI

function ItemToolsUI:New(mcm)
    local window
    local instance = setmetatable({
        Window = nil, -- Will be set below
        Settings = {},
        HotKeys = {},
        Ready = false,
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

    -- EquipmentSelector needs CharacterTools.CharSelector.SelectedCharacter
    -- We assume CharacterTools is initialized first and globally accessible.
    self.EquipmentSelector = EquipmentSelector:New(self.Window, function(eqData) self:OnEquipmentChange(eqData) end)
    self.EquipmentSelector.Container.SameLine = true
    self.EquipmentSelector:Init()

    self.TabBar = self.Window:AddTabBar("UCT_ItemTabBar")

    self.EquipmentTab = EquipmentTab:New(self.TabBar)
    self.PassiveTab = PassiveTab:New(self.TabBar, "ItemTools") -- Add PassiveTab to ItemTools
    self.StatusTab = StatusTab:New(self.TabBar, "ItemTools") -- Add StatusTab to ItemTools
    self.ConsumableTab = ConsumableTab:New(self.TabBar)

    self.EquipmentTab:Init()
    self.PassiveTab:Init() -- Initialize ItemTools' PassiveTab
    self.StatusTab:Init() -- Initialize ItemTools' StatusTab
    self.ConsumableTab:Init()
    self.Ready = true
end

function ItemToolsUI:OnEquipmentChange(eqData)
    -- This function will be called when the equipment selection changes.
    -- Let's force a redraw of the added/applied sections for relevant tabs in CharacterTools.
    if CharacterTools then
        -- Refresh CharacterTools' PassiveTab and StatusTab if they are visible
        if CharacterTools.PassiveTab and CharacterTools.PassiveTab.Tab.Visible then CharacterTools.PassiveTab:GetAddedPassives() end
        if CharacterTools.StatusTab and CharacterTools.StatusTab.Tab.Visible then CharacterTools.StatusTab:GetAppliedStatuses() end
    end
    -- Also refresh ItemTools' own PassiveTab and StatusTab
    if self.PassiveTab and self.PassiveTab.Tab.Visible then self.PassiveTab:GetAddedPassives() end
    if self.StatusTab and self.StatusTab.Tab.Visible then self.StatusTab:GetAppliedStatuses() end
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

---------------------------------------------------------------------------------------------------
--                                       MCM Integration
---------------------------------------------------------------------------------------------------

if MCMActive then
    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Character Tools", function(mcm)
        CharacterTools = CharacterToolsUI:New(mcm)
        CharacterTools:Initialize()
        return CharacterTools.Window
    end)
    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Item Tools", function(mcm)
        ItemTools = ItemToolsUI:New(mcm)
        ItemTools:Initialize()
        return ItemTools.Window
    end)
else
    -- For standalone mod (without MCM), create both windows
    CharacterTools = CharacterToolsUI:New(nil)
    CharacterTools:Initialize()

    ItemTools = ItemToolsUI:New(nil)
    ItemTools:Initialize()
end

Ext.Events.GameStateChanged:Subscribe(function(ev)
    if CharacterTools and CharacterTools.Ready and CharacterTools.CharSelector and ev.ToState == "Running" then
        USERID = _C().Uuid.EntityUuid
        CharacterTools.CharSelector:Init()
    end
end)

return {
    CharacterTools = CharacterTools,
    ItemTools = ItemTools,
    UI_Utils = UI_Utils,
}