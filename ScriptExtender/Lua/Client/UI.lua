USERID = nil
ViewPort = Ext.IMGUI.GetViewportSize()
ViewPortScale = Ext.IMGUI.GetViewportSize()[2] / 1440
MCMActive = Mods and Mods.BG3MCM

-- Global instances for CharacterTools and ItemTools UIs
CharacterTools = nil
ItemTools = nil
MiscTools = nil

local UI_Events = Ext.Require("Client/UI_Events.lua")
local UIState = Ext.Require("Client/UIState.lua")
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
    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, "Misc Tools", function(mcm)
        MiscTools = MiscToolsUI:New(mcm)
        MiscTools:Initialize()
        return MiscTools.Window
    end)
else
    -- For standalone mod (without MCM), create both windows
    CharacterTools = CharacterToolsUI:New(nil)
    CharacterTools:Initialize()

    ItemTools = ItemToolsUI:New(nil)
    ItemTools:Initialize()

    MiscTools = MiscToolsUI:New(nil)
    MiscTools:Initialize()
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