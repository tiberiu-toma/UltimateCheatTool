local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")

---@class RecruitTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field RecruitOptions ExtuiGroup
RecruitTab = {}
RecruitTab.__index = RecruitTab

---@param holder ExtuiTabBar

function RecruitTab:New(holder)
    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("UCT_CompanionTab_Label", "Companions")),
    }, RecruitTab)
    return instance
end

function RecruitTab:ShowCompanions()
    UI_Utils.DestroyChildren(self.RecruitOptions)

    local t = self.RecruitOptions:AddTable("CompanionGrid", 4)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row

    for name,uuid in kpairs(HLP.Companions) do
        if (i - 1) % 4 == 0 then
            row = t:AddRow()
        end
        
        name = HLP.Ucfirst(name)

        if name == "Shadowheart" then name = "ShadowHeart" end

        local cell = row:AddCell()
        local companion = cell:AddImageButton("##Companion" .. uuid, "EC_Portrait_" .. name, {100*ViewPortScale, 100*ViewPortScale})
        local txt = cell:AddText(name)
        local popup = cell:AddPopup("AddItem" .. uuid)

        companion.OnClick = function()
            popup:Open()
        end

        local select = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb78", "Recruit") .. "##Recruit" .. uuid)
        popup:AddSeparator()

        local actionsTable = popup:AddTable("RecruitActionsTable" .. uuid, 2)
        actionsTable.SizingFixedSame = false
        actionsTable.NoHostExtendX = true

        local row1 = actionsTable:AddRow()
        local approvalMax = row1:AddCell():AddButton(LCL.Get("UCT_RecruitTab_MaxApproval", "Max Approval") .. "##MaxApproval" .. uuid)
        local approvalMin = row1:AddCell():AddButton(LCL.Get("UCT_RecruitTab_MinApproval", "Minimum Approval") .. "##MinApproval" .. uuid)
        local row2 = actionsTable:AddRow()
        local approvalPlus = row2:AddCell():AddButton(LCL.Get("UCT_RecruitTab_Plus10Approval", "+10 Approval") .. "##Plus10Approval" .. uuid)
        local approvalMinus = row2:AddCell():AddButton(LCL.Get("UCT_RecruitTab_Minus10Approval", "-10 Approval") .. "##Minus10Approval" .. uuid)

        select.OnClick = function()
            SMS.RecruitCompanion:SendToServer({ data=name })
        end
        approvalMax.OnClick = function()
            SMS.CompanionApproval:SendToServer({ data=name,approval=100 })
        end
        approvalMin.OnClick = function()
            SMS.CompanionApproval:SendToServer({ data=name,approval=-50 })
        end
        approvalPlus.OnClick = function()
            SMS.CompanionApproval:SendToServer({ data=name,approval="+10" })
        end
        approvalMinus.OnClick = function()
            SMS.CompanionApproval:SendToServer({ data=name,approval="-10" })
        end

        local companionInfoFields = {
            { key = "uuid", label = "UUID" },
        }
        -- The data is just the uuid, so we create a small table for InfoPopup
        InfoPopup:AddInfo(popup, { uuid = uuid }, companionInfoFields)

        i = i + 1

        ::continue::
    end
end

function RecruitTab:Init()
    self.Description = self.Tab:AddText(LCL.Get("UCT_RecruitTab_Description", "Change approval or recruit any companion and teleport them to your location. Works regardless of story progression"))

    self.RecruitOptions = self.Tab:AddGroup("Companions")
    self:ShowCompanions()
end

return RecruitTab