USERID = nil
ViewPort = Ext.IMGUI.GetViewportSize()
ViewPortScale = Ext.IMGUI.GetViewportSize()[2] / 1440
MCMActive = Mods and Mods.BG3MCM

-- Global instances for CharacterTools and ItemTools UIs
CharacterTools = nil
ItemTools = nil
MiscTools = nil

local UI_Events = Ext.Require("Client/UI/UIEvents.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local CharacterToolsUI = Ext.Require("Client/UI/CharacterToolsUI.lua")
local ItemToolsUI = Ext.Require("Client/UI/ItemToolsUI.lua")
local MiscToolsUI = Ext.Require("Client/UI/MiscToolsUI.lua")

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

---------------------------------------------------------------------------------------------------
--                                       MCM Integration
---------------------------------------------------------------------------------------------------

--- Initializes a tool window, either in MCM or as a standalone window.
---@param uiClass table The class of the UI window to create (e.g., CharacterToolsUI).
---@param globalName string The name of the global variable to assign the instance to.
---@param tabLabel string The label for the MCM tab.
---@param useMCM boolean True if integrating with MCM, false for standalone.
local function _InitializeToolWindow(uiClass, globalName, tabLabel, useMCM)
    if useMCM then
        Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, tabLabel, function(mcm)
            local instance = uiClass:New(mcm)
            instance:Initialize()
            _G[globalName] = instance -- Assign to global
            return instance.Window
        end)
    else
        local instance = uiClass:New(nil)
        instance:Initialize()
        _G[globalName] = instance -- Assign to global
    end
end

local toolWindows = {
    { class = CharacterToolsUI, global = "CharacterTools", label = "Character Tools" },
    { class = ItemToolsUI, global = "ItemTools", label = "Item Tools" },
    { class = MiscToolsUI, global = "MiscTools", label = "Misc Tools" },
}

if MCMActive then
    for _, windowConfig in ipairs(toolWindows) do
        _InitializeToolWindow(windowConfig.class, windowConfig.global, windowConfig.label, true)
    end
else
    for _, windowConfig in ipairs(toolWindows) do
        _InitializeToolWindow(windowConfig.class, windowConfig.global, windowConfig.label, false)
    end
end

Ext.Events.GameStateChanged:Subscribe(function(ev)
    if CharacterTools and CharacterTools.Ready and CharacterTools.CharSelector and ev.ToState == "Running" then
        USERID = _C().Uuid.EntityUuid
        local charUUID = _C().Uuid.EntityUuid
        USERID = charUUID
        -- Set initial character state and trigger initial data fetches
        UIState:SetSelectedCharacter(charUUID)
        CharacterTools.CharSelector:Init()
    end
end)

return {
    CharacterTools = CharacterTools,
    ItemTools = ItemTools,
    MiscTools = MiscTools,
    UI_Utils = UI_Utils,
}