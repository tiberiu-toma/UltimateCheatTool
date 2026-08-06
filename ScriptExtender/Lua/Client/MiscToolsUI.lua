local UI_Events = Ext.Require("Client/UI_Events.lua")
local UIState = Ext.Require("Client/UIState.lua")
local NPCTab = Ext.Require("Client/NPCTab.lua")
local WaypointTab = Ext.Require("Client/WaypointTab.lua")

---@class MiscToolsUI
---@field Ready boolean
---@field Window ExtuiChildWindow
---@field TabBar ExtuiTabBar
---@field NPCTab NPCTab
---@field WaypointTab WaypointTab
MiscToolsUI = {}
MiscToolsUI.__index = MiscToolsUI

function MiscToolsUI:New(mcm)
    local window
    local instance = setmetatable({
        Window = nil,
        Ready = false,
    }, MiscToolsUI)

    if mcm then
        instance.Window = mcm:AddChildWindow("UltimateCheatTool_MiscTools")
    else
        instance.Window = Ext.IMGUI.NewWindow("Ultimate Cheat Tool (Misc Tools)")
        instance.Window.Open = true
    end
    return instance
end

function MiscToolsUI:Initialize()
    if self.Ready then return end

    self.TabBar = self.Window:AddTabBar("UCT_MiscTabBar")

    self.NPCTab = NPCTab:New(self.TabBar)
    self.WaypointTab = WaypointTab:New(self.TabBar)

    self.NPCTab:Init()
    self.WaypointTab:Init()

    self.Ready = true
end

function MiscToolsUI:HideWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:CloseMCMWindow()
    else
        if self.Window then
            self.Window.Open = false
        end
    end
end

function MiscToolsUI:ShowWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:OpenMCMWindow()
    else
        if self.Window then
            self.Window.Open = true
        end
    end
end

return MiscToolsUI