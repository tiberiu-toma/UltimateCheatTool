local UI_Events = Ext.Require("Client/UI/UIEvents.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local CharacterSelector = Ext.Require("Client/UI/Components/CharacterSelector.lua")
local GenericTab = Ext.Require("Client/UI/Tabs/GenericTab.lua")
local SpellTab = Ext.Require("Client/UI/Tabs/SpellTab.lua")
local PassiveTab = Ext.Require("Client/UI/Tabs/PassiveTab.lua")
local StatusTab = Ext.Require("Client/UI/Tabs/StatusTab.lua")
local ResourceTab = Ext.Require("Client/UI/Tabs/ResourceTab.lua")
local AbilityTab = Ext.Require("Client/UI/Tabs/AbilityTab.lua")
local SkillsTab = Ext.Require("Client/UI/Tabs/SkillsTab.lua")
local TagTab = Ext.Require("Client/UI/Tabs/TagTab.lua")
local ProficiencyTab = Ext.Require("Client/UI/Tabs/ProficiencyTab.lua")
local ResistanceTab = Ext.Require("Client/UI/Tabs/ResistanceTab.lua")
local ReactionTab = Ext.Require("Client/UI/Tabs/ReactionTab.lua")
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
---@field ResourceTab ResourceTab
---@field AbilityTab AbilityTab
---@field SkillsTab SkillsTab
---@field ProficiencyTab ProficiencyTab
---@field ResistanceTab ResistanceTab
---@field ReactionTab ReactionTab
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
        if self.PassiveTab and self.PassiveTab.Tab.Visible then self.PassiveTab:GetAppliedModifications() end
        if self.StatusTab and self.StatusTab.Tab.Visible then self.StatusTab:GetAppliedModifications() end
        if self.ResourceTab and self.ResourceTab.Tab.Visible then self.ResourceTab:GetAddedResources() end
        if self.AbilityTab and self.AbilityTab.Tab.Visible then self.AbilityTab:FetchAbilities(true) end
        if self.SkillsTab and self.SkillsTab.Tab.Visible then self.SkillsTab:Draw() end
        if self.ProficiencyTab and self.ProficiencyTab.Tab.Visible then self.ProficiencyTab:Draw() end
        if self.ResistanceTab and self.ResistanceTab.Tab.Visible then self.ResistanceTab:Draw() end
        if self.ReactionTab and self.ReactionTab.Tab.Visible then self.ReactionTab:GetLearnedReactions() end
    end)

    self.TabBar = self.Window:AddTabBar("UCT_CharacterTabBar")

    self.GenericTab = GenericTab:New(self.TabBar)
    self.SpellTab = SpellTab:New(self.TabBar)
    self.ReactionTab = ReactionTab:New(self.TabBar)
    self.PassiveTab = PassiveTab:New(self.TabBar, "CharacterTools") -- Add PassiveTab to CharacterTools
    self.StatusTab = StatusTab:New(self.TabBar, "CharacterTools") -- Add StatusTab to CharacterTools
    self.ResourceTab = ResourceTab:New(self.TabBar)
    self.AbilityTab = AbilityTab:New(self.TabBar)
    self.SkillsTab = SkillsTab:New(self.TabBar)
    self.TagTab = TagTab:New(self.TabBar)
    self.ProficiencyTab = ProficiencyTab:New(self.TabBar)
    self.ResistanceTab = ResistanceTab:New(self.TabBar)
    self.RecruitTab = RecruitTab:New(self.TabBar)
    --self.ResetTab = ResetTab:New(self.TabBar)

    self.GenericTab:Init()
    self.SpellTab:Init()
    self.ReactionTab:Init()
    self.PassiveTab:Init() -- Initialize CharacterTools' PassiveTab
    self.StatusTab:Init() -- Initialize CharacterTools' StatusTab
    self.ResourceTab:Init()
    self.AbilityTab:Init()
    self.SkillsTab:Init()
    self.TagTab:Init()
    self.ProficiencyTab:Init()
    self.ResistanceTab:Init()
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