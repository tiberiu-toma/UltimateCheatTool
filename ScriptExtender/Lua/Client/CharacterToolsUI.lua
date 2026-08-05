local UI_Events = Ext.Require("Client/UI_Events.lua")
local UIState = Ext.Require("Client/UIState.lua")
local CharacterSelector = Ext.Require("Client/CharacterSelector.lua")
local GenericTab = Ext.Require("Client/GenericTab.lua")
local RecruitTab = Ext.Require("Client/RecruitTab.lua")
local NPCTab = Ext.Require("Client/NPCTab.lua")
local PassiveTab = Ext.Require("Client/PassiveTab.lua")
local StatusTab = Ext.Require("Client/StatusTab.lua")
local TagTab = Ext.Require("Client/TagTab.lua")
local SpellTab = Ext.Require("Client/SpellTab.lua")
local WaypointTab = Ext.Require("Client/WaypointTab.lua")
local ResetTab = Ext.Require("Client/ResetTab.lua")

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

    USERID = _C().Uuid.EntityUuid

    self.CharSelector = CharacterSelector:New(self.Window)
    self.CharSelector:Init()

    UI_Events:Subscribe("CharacterChanged", function(charUUID)
        -- Refresh character-specific tabs within this UI
        if self.SpellTab and self.SpellTab.Tab.Visible then self.SpellTab:GetLearnedSpells() end
        if self.TagTab and self.TagTab.Tab.Visible then self.TagTab:GetAppliedTags() end
        if self.PassiveTab and self.PassiveTab.Tab.Visible then self.PassiveTab:GetAddedPassives() end
        if self.StatusTab and self.StatusTab.Tab.Visible then self.StatusTab:GetAppliedStatuses() end
    end)

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

function CharacterToolsUI:HideWindows()
    if MCMActive then
        Mods.BG3MCM.IMGUIAPI:CloseMCMWindow()
    else
        if self.Window then
            self.Window.Open = false
        end
    end
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

return CharacterToolsUI