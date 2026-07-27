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

    return UTL.Paginate(allMatchingStatuses, page, pageSize)
end

function STAT.Apply(char, statusId, remove)
    if remove then
        Osi.RemoveStatus(char, statusId)
    else
        Osi.ApplyStatus(char, statusId, -1, 1)
    end
end