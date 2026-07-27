---@class Pagination
--- A reusable UI component for creating pagination controls.
Pagination = {}
Pagination.__index = Pagination

---@return Pagination
function Pagination:New()
    local instance = setmetatable({}, Pagination)
    return instance
end

--- Creates a set of pagination controls.
---@param options table { parent: ExtuiGroup, idSuffix: string, currentPage: number, totalPages: number, onPageChange: function }
function Pagination:CreateControls(options)
    local paginationArea = options.parent
    local idSuffix = options.idSuffix or ""
    local currentPage = options.currentPage
    local totalPages = options.totalPages
    local onPageChange = options.onPageChange

    if not paginationArea or not onPageChange then
        Ext.Utils.PrintError("Pagination:CreateControls requires 'parent' and 'onPageChange' options.")
        return
    end

    if not totalPages or totalPages <= 1 then
        return
    end

    local paginationGroup = paginationArea:AddGroup("Pagination" .. idSuffix)

    local prevBtn = paginationGroup:AddButton("<##Prev" .. idSuffix)
    prevBtn.SameLine = false
    if currentPage <= 1 then
        prevBtn.Disabled = true
    end
    prevBtn.OnClick = function()
        onPageChange(currentPage - 1)
    end

    local paginationText = paginationGroup:AddText("Page " .. currentPage .. " of " .. totalPages)
    paginationText.SameLine = true

    local nextBtn = paginationGroup:AddButton(">##Next" .. idSuffix)
    nextBtn.SameLine = true
    if currentPage >= totalPages then
        nextBtn.Disabled = true
    end
    nextBtn.OnClick = function()
        onPageChange(currentPage + 1)
    end
end

return Pagination:New()