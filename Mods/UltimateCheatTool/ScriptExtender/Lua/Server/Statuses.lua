STAT = {}
STAT.Max = 50

function STAT.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = STAT.Max

    local itemData = Ext.Stats.GetStats("StatusData")

    local allMatchingStatuses = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")
        local displayName = Ext.Loca.GetTranslatedString(handle)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "" then
            table.insert(allMatchingStatuses, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
            })
        end
    end

    table.sort(allMatchingStatuses, function(a, b) return a.displayName < b.displayName end)

    local totalItems = #allMatchingStatuses
    local totalPages = math.ceil(totalItems / pageSize)
    if page > totalPages and totalPages > 0 then page = totalPages end
    if page < 1 then page = 1 end

    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalItems)

    local statusesForPage = {}
    for i = startIndex, endIndex do
        local status = allMatchingStatuses[i]
        if status then
            statusesForPage[status.id] = status
        end
    end

    return statusesForPage, totalItems, totalPages, page
end

function STAT.Apply(char, statusId, remove)
    if remove then
        Osi.RemoveStatus(char, statusId)
    else
        Osi.ApplyStatus(char, statusId, -1, 1)
    end
end