local UI_Events = Ext.Require("Client/UI/UIEvents.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local CharacterSelector = Ext.Require("Client/UI/Components/CharacterSelector.lua")
local GenericTab = Ext.Require("Client/UI/Tabs/GenericTab.lua")
local SpellTab = Ext.Require("Client/UI/Tabs/SpellTab.lua")
local PassiveTab = Ext.Require("Client/UI/Tabs/PassiveTab.lua")
local StatusTab = Ext.Require("Client/UI/Tabs/StatusTab.lua")
local TagTab = Ext.Require("Client/UI/Tabs/TagTab.lua")
local RecruitTab = Ext.Require("Client/UI/Tabs/RecruitTab.lua")
--local ResetTab = Ext.Require("Client/UI/Tabs/ResetTab.lua")

---@class CharacterToolsUI
---@field Ready boolean
---@field Window ExtuiChildWindow
---@field Settings table<string, any>
---@field HotKeys table<string, any>
---@field CharSelector CharacterSelector
---@field TabBar ExtuiTabBar
---@field GenericTab GenericTab
---@field SpellTab SpellTab
---@field RecruitTab RecruitTab
---@field TagTab TagTab
---@field PassiveTab PassiveTab
---@field StatusTab StatusTab
-----@field ResetTab ResetTab
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
    self.SpellTab = SpellTab:New(self.TabBar)
    self.PassiveTab = PassiveTab:New(self.TabBar, "CharacterTools") -- Add PassiveTab to CharacterTools
    self.StatusTab = StatusTab:New(self.TabBar, "CharacterTools") -- Add StatusTab to CharacterTools
    self.TagTab = TagTab:New(self.TabBar)
    self.RecruitTab = RecruitTab:New(self.TabBar)
    --self.ResetTab = ResetTab:New(self.TabBar)

    self.GenericTab:Init()
    self.SpellTab:Init()
    self.PassiveTab:Init() -- Initialize CharacterTools' PassiveTab
    self.StatusTab:Init() -- Initialize CharacterTools' StatusTab
    self.TagTab:Init()
    self.RecruitTab:Init()
    --self.ResetTab:Init()

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