PASSV = {}
PASSV.Max = 50

function PASSV.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = PASSV.Max

    local itemData = Ext.Stats.GetStats("PassiveData")

    local allMatchingPassives = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")

        local displayName = Ext.Loca.GetTranslatedString(handle)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName))

        if matchesSearch and displayName and displayName ~= "" then
            table.insert(allMatchingPassives, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
            })
        end
    end

    table.sort(allMatchingPassives, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingPassives, page, pageSize)
end

function PASSV.Learn(passiveId, unlearn)
    if unlearn then
        Osi.RemovePassive(GetHostCharacter(), passiveId)
    else
        Osi.AddPassive(GetHostCharacter(), passiveId)
    end
end