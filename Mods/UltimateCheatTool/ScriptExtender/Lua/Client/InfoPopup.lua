---@class InfoPopup
--- A reusable UI component for creating info popups.
InfoPopup = {}
InfoPopup.__index = InfoPopup

function InfoPopup:New()
    return setmetatable({}, InfoPopup)
end

---@param popup ExtuiPopup
---@param data table
---@param fields table
function InfoPopup:AddInfo(popup, data, fields)
    for _, field in ipairs(fields) do
        local value = HLP.GetAttr(data, field.key)
        
        local text
        if value ~= nil and value ~= "" then
            if field.formatter then
                text = field.formatter(value)
            else
                text = tostring(value)
            end
        end

        if text then
            local label = field.label or ""
            if label ~= "" then
                label = label .. ": "
            end

            local textElement = popup:AddText(label .. text)
            if field.sameLine == false then
                textElement.SameLine = false
            end
        end
    end
end

return InfoPopup:New()