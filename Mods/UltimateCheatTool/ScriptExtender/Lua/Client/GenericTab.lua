---@class GenericTab
---@field Tab ExtuiTabItem
GenericTab = {}
GenericTab.__index = GenericTab

---@param holder ExtuiTabBar
function GenericTab:New(holder)
    if UI.GenericTab then return end

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("UCT_GenericTab_Label", "Generic")),
    }, GenericTab)
    return instance
end

function GenericTab:Init()
    -- Character Actions
    local actionsGroup = self.Tab:AddGroup("CharacterActions")
    actionsGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_CharacterActions", "Character Actions"))
    local actionsTable = actionsGroup:AddTable("ActionsTable", 2)
    actionsTable.SizingFixedSame = true
    actionsTable.NoHostExtendX = true
    
    local actionsRow1 = actionsTable:AddRow()
    
    local restorePartyBtn = actionsRow1:AddCell():AddButton(LCL.Get("UCT_GenericTab_RestoreParty", "Restore Party"))
    restorePartyBtn.OnClick = function()
        SMS.RestoreParty:SendToServer({})
    end

    local resetCooldownsBtn = actionsRow1:AddCell():AddButton(LCL.Get("UCT_GenericTab_ResetCooldowns", "Reset Cooldowns"))
    resetCooldownsBtn.OnClick = function()
        local charUUID = UI.CharSelector.SelectedCharacter
        SMS.ResetCooldowns:SendToServer({ ID = charUUID })
    end

    local actionsRow2 = actionsTable:AddRow()

    local respecBtn = actionsRow2:AddCell():AddButton(LCL.Get("UCT_GenericTab_StartRespec", "Respec Character"))
    respecBtn.OnClick = function()
        local charUUID = UI.CharSelector.SelectedCharacter
        SMS.StartRespec:SendToServer({ ID = charUUID })
    end

    local appearanceBtn = actionsRow2:AddCell():AddButton(LCL.Get("UCT_GenericTab_ChangeAppearance", "Change Appearance"))
    appearanceBtn.OnClick = function()
        local charUUID = UI.CharSelector.SelectedCharacter
        SMS.StartChangeAppearance:SendToServer({ ID = charUUID })
    end
    self.Tab:AddSeparator()

    -- Resources
    local resourcesGroup = self.Tab:AddGroup("Resources")
    resourcesGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_AddResources", "Add Resources"))
    local resourcesTable = resourcesGroup:AddTable("ResourcesTable", 6)
    resourcesTable.NoHostExtendX = true

    -- Gold Row
    local goldRow = resourcesTable:AddRow()
    goldRow:AddCell():AddText(LCL.Get("UCT_GenericTab_AddGold", "Add Gold:"))
    local goldAmounts = {1000, 10000, 50000, 100000}
    for _, amount in ipairs(goldAmounts) do
        local btn = goldRow:AddCell():AddButton("Add " .. amount .. "##Gold" .. tostring(amount))
        btn.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.AddGold:SendToServer({ ID = charUUID, Amount = amount })
        end
    end

    -- Experience Row
    local expRow = resourcesTable:AddRow()
    expRow:AddCell():AddText(LCL.Get("UCT_GenericTab_AddExperience", "Add Experience:"))
    local expAmounts = {1000, 10000, 50000, 100000}
    for _, amount in ipairs(expAmounts) do
        local btn = expRow:AddCell():AddButton("Add " .. amount .. " XP##XP" .. tostring(amount))
        btn.OnClick = function()
            SMS.AddExperience:SendToServer({ Amount = amount })
        end
    end

    -- Inspiration Row
    local inspirationRow = resourcesTable:AddRow()
    inspirationRow:AddCell():AddText(LCL.Get("UCT_GenericTab_AddInspiration", "Add Inspiration:"))
    local inspirationAmounts = {1, 2, 3, 4}
    for _, amount in ipairs(inspirationAmounts) do
        local btn = inspirationRow:AddCell():AddButton("Add " .. amount .. "##Inspiration" .. tostring(amount))
        btn.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.AddInspiration:SendToServer({ ID = charUUID, Amount = amount })
        end
    end

    -- Tadpoles Row
    local tadpoleRow = resourcesTable:AddRow()
    tadpoleRow:AddCell():AddText(LCL.Get("UCT_GenericTab_AddTadpoles", "Add Tadpoles:"))
    local tadpoleAmounts = {1, 5, 10, 25}
    for _, amount in ipairs(tadpoleAmounts) do
        local btn = tadpoleRow:AddCell():AddButton("Add " .. amount .. "##Tadpole" .. tostring(amount))
        btn.OnClick = function()
            local charUUID = UI.CharSelector.SelectedCharacter
            SMS.AddTadpoles:SendToServer({ ID = charUUID, Amount = amount })
        end
    end
    self.Tab:AddSeparator()
end

return GenericTab