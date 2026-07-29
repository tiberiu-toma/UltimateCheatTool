UTL = {}

function GetTableKeys(tbl, prefix, result)
    result = result or {}
    prefix = prefix or ""

    for k, v in pairs(tbl) do
        local full_key = prefix ~= "" and (prefix .. "." .. tostring(k)) or tostring(k)
        table.insert(result, full_key)

        if type(v) == "table" then
            GetTableKeys(v, full_key, result)
        end
    end

    return result
end

--- Paginates a flat array of items.
---@param allItems table The array of items to paginate.
---@param page number The current page number.
---@param pageSize number The number of items per page.
---@return table The items for the current page (as a map by item.id).
---@return number The total number of items.
---@return number The total number of pages.
---@return number The current page number (sanitized).
function UTL.Paginate(allItems, page, pageSize)
    local totalItems = #allItems
    if totalItems == 0 then
        return {}, 0, 1, 1
    end

    local totalPages = math.ceil(totalItems / pageSize)
    if page > totalPages and totalPages > 0 then page = totalPages end
    if page < 1 then page = 1 end

    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalItems)

    local itemsForPage = {}
    for i = startIndex, endIndex do
        local item = allItems[i]
        if item and item.id then
            itemsForPage[item.id] = item
        end
    end

    return itemsForPage, totalItems, totalPages, page
end