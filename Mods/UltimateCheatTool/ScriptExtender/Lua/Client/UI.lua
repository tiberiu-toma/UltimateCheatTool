USERID = nil
ViewPort = Ext.IMGUI.GetViewportSize()
ViewPortScale = Ext.IMGUI.GetViewportSize()[2] / 1440
MCMActive = Mods and Mods.BG3MCM -- true or false depending on if MCM is active without storing it in a global variable

---@class UI
---@field Ready boolean
---@field Window ExtuiWindow|ExtuiChildWindow
---@field Settings table<string, any>
---@field HotKeys table<string, any>
---@field Await table<string, any>
---@field KeyInputHandler LuaEventBase|nil
---@field MouseInputHandler LuaEventBase|nil
---@field ControllerInputHandler LuaEventBase|nil
---@field ControllerAxisHandler LuaEventBase|nil
---@field TabBar ExtuiTabBar
---@field TagTab TagTab
---@field GenericTab GenericTab
---@field EquipmentTab EquipmentTab
---@field ConsumableTab ConsumableTab
---@field SpellTab SpellTab
---@field PassiveTab PassiveTab
---@field StatusTab StatusTab
---@field RecruitTab RecruitTab
---@field NPCTab NPCTab
---@field WaypointTab WaypointTab
UI = {
    Ready = false,
}
UI.__index = UI

local EquipmentTab = Ext.Require("Client/EquipmentTab.lua")
local NPCTab = Ext.Require("Client/NPCTab.lua")
local SpellTab = Ext.Require("Client/SpellTab.lua")
local PassiveTab = Ext.Require("Client/PassiveTab.lua")
local StatusTab = Ext.Require("Client/StatusTab.lua")
local ConsumableTab = Ext.Require("Client/ConsumableTab.lua")
local WaypointTab = Ext.Require("Client/WaypointTab.lua")
local RecruitTab = Ext.Require("Client/RecruitTab.lua")
local TagTab = Ext.Require("Client/TagTab.lua")
local GenericTab = Ext.Require("Client/GenericTab.lua")

--------------------------------------------------
--------------------------------------------------

function UI:New(mcm)
    local window
    if mcm then
        window = mcm:AddChildWindow("UltimateCheatTool")
    end

    self.Window = window
    self.Settings = {}
    self.HotKeys = {}

    USERID = _C().Uuid.EntityUuid
    return self
end

function UI:Init()
   -- self.PartyInterface = PartyInterface:New(self.Window)
   -- self.PartyInterface:Init()

    self.TabBar = self.Window:AddTabBar("")
    
    self.GenericTab = GenericTab:New(self.TabBar)
    self.EquipmentTab = EquipmentTab:New(self.TabBar)
    self.ConsumableTab = ConsumableTab:New(self.TabBar)
    self.SpellTab = SpellTab:New(self.TabBar)
    self.PassiveTab = PassiveTab:New(self.TabBar)
    self.StatusTab = StatusTab:New(self.TabBar)
    self.RecruitTab = RecruitTab:New(self.TabBar)
    self.NPCTab = NPCTab:New(self.TabBar)
    self.TagTab = TagTab:New(self.TabBar)
    self.WaypointTab = WaypointTab:New(self.TabBar)

    self.GenericTab:Init()
    self.EquipmentTab:Init()
    self.ConsumableTab:Init()
    self.SpellTab:Init()
    self.PassiveTab:Init()
    self.StatusTab:Init()
    self.RecruitTab:Init()
    self.NPCTab:Init()
    self.TagTab:Init()
    self.WaypointTab:Init()

    
    self.Ready = true
    -- Event.UIInitialized:SendToServer({ID = USERID})
    -- Send ModEvent about UI being ready
end

---Set tab visibility from LocalSettings default fallback
---@param tab table The tab object with a Tab property
---@param settingsKey string The LocalSettings key (e.g., "Tab_Debug")
---@param defaultVisible boolean The default visibility if not in LocalSettings
function UI:SetDefaultTabVisibility(tab, settingsKey, defaultVisible)
    local visibilitySettings = LocalSettings:GetOr({ Visible = defaultVisible }, settingsKey)
    if type(visibilitySettings) ~= "table" then
        visibilitySettings = { Visible = defaultVisible }
        LocalSettings:AddOrChange(settingsKey, visibilitySettings)
    end
    tab.Tab.Visible = visibilitySettings.Visible
end

function UI:HideWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:CloseMCMWindow()
    else
        if self.Window then
            self.Window.Open = false
        end
    end
    if self.SceneControl and self.SceneControl.ActiveSceneControls then
        for _,sceneControl in pairs(self.SceneControl.ActiveSceneControls) do
            sceneControl.TempClosed = true
            sceneControl.Window.Open = false
        end
    end
end
function UI:ShowWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:OpenMCMWindow()
    else
        if self.Window then
            self.Window.Open = true
        end
        for _,sceneControl in pairs(self.SceneControl.ActiveSceneControls) do
            if sceneControl.TempClosed == true then
                sceneControl.Window.Open = true
                sceneControl.TempClosed = false
            end
        end
    end
end

function UI.DestroyChildren(obj)
    if obj == nil then
        return
    end
    if HLP.GetAttr(obj, "Children") and #obj.Children > 0 then
        for _,child in pairs(obj.Children) do
            child:Destroy()
        end
    end
end
---------------------------------------------------------------------------------------------------
--                                       Load MCM Tab
---------------------------------------------------------------------------------------------------

if MCMActive then
    ----print("Inserting into MCM")
    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "UltimateCheatTool", function(mcm)
        UI:New(mcm):Init()
    end)
end

return UI