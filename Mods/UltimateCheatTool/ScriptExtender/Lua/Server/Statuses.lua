STAT = {}
STAT.Max = 50000

function STAT.GetAll(search)
    search = search or ""

    local itemData = Ext.Stats.GetStats("StatusData")

    local statusCount = 0
    local statuses = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")

        local displayName = Ext.Loca.GetTranslatedString(handle)

        local matchesSearch = true

        if search ~= "" then
            matchesSearch = HLP.StrContains(search, displayName)
        end

        if matchesSearch and displayName and displayName ~= "" then
            statusCount = statusCount + 1
            
            statuses[id] = {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
            }
        end
            
        if HLP.Count(statuses) >= STAT.Max then break end 
    end

    return statuses
end

function STAT.Apply(char, statusId, remove)
    if remove then
        Osi.RemoveStatus(char, statusId)
    else
        Osi.ApplyStatus(char, statusId, -1, 1)
    end
end