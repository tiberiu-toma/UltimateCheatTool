---@class ResetTab
---@field Tab ExtuiTabItem
---@field ResetArea ExtuiGroup
ResetTab = {}
ResetTab.__index = ResetTab

---@param holder ExtuiTabBar
function ResetTab:New(holder)
    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("hc0d4bc9d06de4fa685d800fe570229c91", "Reset")),
    }, ResetTab)
    return instance
end

function ResetTab:AddResetArea()
    local btn = self.Tab:AddButton(LCL.Get("hc0d4bc9d06de4fa685d800fe570229c92", "Reset All Characters"))

    btn.OnClick = function()
        SMS.RequestResetAll:SendToServer({})
    end
end

function ResetTab:Init()
    if not self.ResetArea then
        self:AddResetArea()
    end
end

return ResetTab
