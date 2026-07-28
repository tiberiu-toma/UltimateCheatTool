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
    -- Gold
    local goldGroup = self.Tab:AddGroup("Gold")
    goldGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_AddGold", "Add Gold"))
    local goldAmounts = {1000, 10000, 50000, 100000}
    local goldTable = goldGroup:AddTable("GoldTable", #goldAmounts)
    goldTable.SizingFixedSame = true
    goldTable.NoHostExtendX = true
    local goldRow = goldTable:AddRow()
    for _, amount in ipairs(goldAmounts) do
        local btn = goldRow:AddCell():AddButton("Add " .. amount)
        btn.OnClick = function()
            SMS.AddGold:SendToServer({ ID = USERID, Amount = amount })
        end
    end
    self.Tab:AddSeparator()

    -- Experience
    local expGroup = self.Tab:AddGroup("Experience")
    expGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_AddXP", "Add Experience"))
    local expAmounts = {1000, 10000, 50000, 100000}
    local expTable = expGroup:AddTable("ExpTable", #expAmounts)
    expTable.SizingFixedSame = true
    expTable.NoHostExtendX = true
    local expRow = expTable:AddRow()
    for _, amount in ipairs(expAmounts) do
        local btn = expRow:AddCell():AddButton("Add " .. amount .. " XP")
        btn.OnClick = function()
            SMS.AddExperience:SendToServer({ ID = USERID, Amount = amount })
        end
    end
    self.Tab:AddSeparator()

    -- Tadpoles
    local tadpoleGroup = self.Tab:AddGroup("Tadpoles")
    tadpoleGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_AddTadpoles", "Add Tadpoles"))
    local tadpoleAmounts = {1, 5, 10, 25, 100}
    local tadpoleTable = tadpoleGroup:AddTable("TadpoleTable", #tadpoleAmounts)
    tadpoleTable.SizingFixedSame = true
    tadpoleTable.NoHostExtendX = true
    local tadpoleRow = tadpoleTable:AddRow()
    for _, amount in ipairs(tadpoleAmounts) do
        local btn = tadpoleRow:AddCell():AddButton("Add " .. amount)
        btn.OnClick = function()
            SMS.AddTadpoles:SendToServer({ ID = USERID, Amount = amount })
        end
    end
    self.Tab:AddSeparator()

    -- Inspiration
    local inspirationGroup = self.Tab:AddGroup("Inspiration")
    inspirationGroup:AddSeparatorText(LCL.Get("UCT_GenericTab_AddInspiration", "Add Inspiration Points"))
    local inspirationAmounts = {1, 2, 3, 4}
    local inspirationTable = inspirationGroup:AddTable("InspirationTable", #inspirationAmounts)
    inspirationTable.SizingFixedSame = true
    inspirationTable.NoHostExtendX = true
    local inspirationRow = inspirationTable:AddRow()
    for _, amount in ipairs(inspirationAmounts) do
        local btn = inspirationRow:AddCell():AddButton("Add " .. amount)
        btn.OnClick = function()
            SMS.AddInspiration:SendToServer({ ID = USERID, Amount = amount })
        end
    end
end

return GenericTab