local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class RecruitTab
---@field Tab ExtuiTabItem
---@field Description ExtuiGroup
---@field RecruitOptions ExtuiGroup
RecruitTab = {}
RecruitTab.__index = RecruitTab

---@param holder ExtuiTabBar

function RecruitTab:New(holder)
    if UI.RecruitTab then return end 

    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("", "Companions")),
    }, RecruitTab)
    return instance
end

function RecruitTab:ShowCompanions()
    UI.DestroyChildren(self.RecruitOptions)

    local t = self.RecruitOptions:AddTable("", 4)
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

        local select = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb78", "Recruit"))
        local approvalMax = popup:AddButton(LCL.Get("", "Max Approval"))
        local approvalMin = popup:AddButton(LCL.Get("", "Minimum Approval"))
        local approvalPlus = popup:AddButton(LCL.Get("", "+10 Approval"))
        local approvalMinus = popup:AddButton(LCL.Get("", "-10 Approval"))

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
    self.Description = self.Tab:AddText("Change approval or recruit any companion and teleport them to your location. Works regardless of story progression")

    self.RecruitOptions = self.Tab:AddGroup("Companions")
    self:ShowCompanions()
end

return RecruitTab