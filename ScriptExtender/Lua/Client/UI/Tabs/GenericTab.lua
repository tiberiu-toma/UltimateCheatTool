local UIState = Ext.Require("Client/UI/UIState.lua")

---@class GenericTab
---@field Tab ExtuiTabItem
GenericTab = {}
GenericTab.__index = GenericTab

---@param holder ExtuiTabBar
function GenericTab:New(holder)
    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("UCT_GenericTab_Label", "Generic")),
    }, GenericTab)
    return instance
end

---@param resourcesTable ExtuiTable
---@param labelHandle string
---@param labelFallback string
---@param amounts table
---@param idPrefix string
---@param smsEvent ExtNet.Channel
---@param buttonTextFormat? string
local function _CreateResourceRow(resourcesTable, labelHandle, labelFallback, amounts, idPrefix, smsEvent, buttonTextFormat)
    buttonTextFormat = buttonTextFormat or "Add %s"
    local row = resourcesTable:AddRow()
    row:AddCell():AddText(LCL.Get(labelHandle, labelFallback))
    for _, amount in ipairs(amounts) do
        local btn = row:AddCell():AddButton(string.format(buttonTextFormat, tostring(amount)) .. "##" .. idPrefix .. tostring(amount))
        btn.OnClick = function() smsEvent:SendToServer({ character = UIState.SelectedCharacter, Amount = amount }) end
    end
end

function GenericTab:Init()
    -- Character Actions
    local actionsGroup = self.Tab:AddGroup("CharacterActions")
    actionsGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_CharacterActions", "Character Actions"))
    local actionsTable = actionsGroup:AddTable("ActionsTable", 2)
    actionsTable.SizingFixedSame = false
    actionsTable.NoHostExtendX = true
    
    local actionsRow1 = actionsTable:AddRow()
    
    local restorePartyBtn = actionsRow1:AddCell():AddButton(LCL.Get("UCT_GenericTab_RestoreParty", "Restore Party"))
    restorePartyBtn.OnClick = function()
        SMS.RestoreParty:SendToServer({})
    end

    local resetCooldownsBtn = actionsRow1:AddCell():AddButton(LCL.Get("UCT_GenericTab_ResetCooldowns", "Reset Cooldowns"))
    resetCooldownsBtn.OnClick = function()
        local charUUID = UIState.SelectedCharacter
        SMS.ResetCooldowns:SendToServer({ character = charUUID })
    end

    local actionsRow2 = actionsTable:AddRow()

    local respecBtn = actionsRow2:AddCell():AddButton(LCL.Get("UCT_GenericTab_StartRespec", "Respec Character"))
    respecBtn.OnClick = function()
        local charUUID = UIState.SelectedCharacter
        SMS.StartRespec:SendToServer({ character = charUUID })
    end

    local appearanceBtn = actionsRow2:AddCell():AddButton(LCL.Get("UCT_GenericTab_ChangeAppearance", "Change Appearance"))
    appearanceBtn.OnClick = function()
        local charUUID = UIState.SelectedCharacter
        SMS.StartChangeAppearance:SendToServer({ character = charUUID })
    end
    self.Tab:AddSeparator()

    -- Resources
    local resourcesGroup = self.Tab:AddGroup("Resources")
    resourcesGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_AddResources", "Add Resources"))
    local resourcesTable = resourcesGroup:AddTable("ResourcesTable", 5)
    resourcesTable.NoHostExtendX = true

    _CreateResourceRow(resourcesTable, "UCT_GenericTab_AddGold", "Add Gold:", {1000, 10000, 50000, 100000}, "Gold", SMS.AddGold)
    _CreateResourceRow(resourcesTable, "UCT_GenericTab_AddExperience", "Add Experience:", {1000, 10000, 50000, 100000}, "XP", SMS.AddExperience, "Add %s XP")
    _CreateResourceRow(resourcesTable, "UCT_GenericTab_AddInspiration", "Add Inspiration:", {1, 2, 3, 4}, "Inspiration", SMS.AddInspiration)
    _CreateResourceRow(resourcesTable, "UCT_GenericTab_AddTadpoles", "Add Tadpoles:", {1, 5, 10, 25}, "Tadpole", SMS.AddTadpoles)
    
    self.Tab:AddSeparator()
end

return GenericTab