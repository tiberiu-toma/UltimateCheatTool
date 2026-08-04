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
---@field CharSelector CharacterSelector
---@field EquipmentSelector EquipmentSelector
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

function UI:OnCharacterChange(charUUID)
    -- This function will be called when the character selection changes.
    -- We can trigger a refresh of the active tab here if needed.
    -- For now, the tabs will read the selected character when they perform actions.
    -- Let's force a redraw of the added/applied sections for relevant tabs.
    self.EquipmentSelector:SetSelectedEquipment(nil) -- Clear selected equipment when character changes
    if self.PassiveTab and self.PassiveTab.Tab.Visible then self.PassiveTab:GetAddedPassives() end
    if self.EquipmentSelector then self.EquipmentSelector:FetchEquippedItems() end
    if self.SpellTab and self.SpellTab.Tab.Visible then self.SpellTab:GetLearnedSpells() end
    if self.TagTab and self.TagTab.Tab.Visible then self.TagTab:GetAppliedTags() end
    if self.StatusTab and self.StatusTab.Tab.Visible then self.StatusTab:GetAppliedStatuses() end
end

function UI:OnEquipmentChange(eqData)
    -- This function will be called when the equipment selection changes.
    if self.PassiveTab and self.PassiveTab.Tab.Visible then
        self.PassiveTab:GetAddedPassives()
        -- Re-fetch the current page to update the button states in the main grid
        self.PassiveTab:FetchData(self.PassiveTab.CurrentPage)
    end
    if self.StatusTab and self.StatusTab.Tab.Visible then
        self.StatusTab:GetAppliedStatuses()
        -- Re-fetch the current page to update the button states in the main grid
        self.StatusTab:FetchData(self.StatusTab.CurrentPage)
    end
end

function UI:Init()
   -- self.PartyInterface = PartyInterface:New(self.Window)
   -- self.PartyInterface:Init()

    self.CharSelector = CharacterSelector:New(self.Window, function(charUUID) self:OnCharacterChange(charUUID) end)
    self.EquipmentSelector = EquipmentSelector:New(self.Window, function(eqData) self:OnEquipmentChange(eqData) end)
    self.EquipmentSelector.Container.SameLine = true

    self.TabBar = self.Window:AddTabBar("UCT_MainTabBar")
    
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

    self.CharSelector:Init()
    self.EquipmentSelector:Init()
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
        self.EquipmentSelector:FetchEquippedItems() -- Refresh quick picks when UI is opened
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

function UI.CenterObjectH(parent, objDef)
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

function UI.CenterObjectV(parent, objDef)
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

--function UI.CenterObject(parent, objDef)
--    if not objDef or not parent then return end
--
--    local table = parent:AddTable("CenteringTable", 3)
--    table.SizingFixedSame = true
--    table.NoHostExtendX = false
--    local row1 = table:AddRow()
--    local row2 = table:AddRow()
--    local row3 = table:AddRow()
--    local topCell = row1:AddCell()
--    row2:AddCell()
--    local centerCell = row2:AddCell()
--    local bottomCell = row3:AddCell()
--    return objDef(centerCell)
--end
---------------------------------------------------------------------------------------------------
--                                       Load MCM Tab
---------------------------------------------------------------------------------------------------

if MCMActive then
    ----print("Inserting into MCM")
    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "UltimateCheatTool", function(mcm)
        UI:New(mcm):Init()
    end)
end

Ext.Events.GameStateChanged:Subscribe(function(ev)
    if UI and UI.Ready and UI.CharSelector and ev.ToState == "Running" then
        USERID = _C().Uuid.EntityUuid
        UI.CharSelector:Init()
    end
end)

return UI