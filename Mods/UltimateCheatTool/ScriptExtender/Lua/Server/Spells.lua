SPLL = {}
SPLL.Max = 50

function SPLL.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = SPLL.Max

    local itemData = Ext.Stats.GetStats("SpellData")

    local allMatchingSpells = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")

        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "unknown" then
            table.insert(allMatchingSpells, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
            })
        end
    end

    table.sort(allMatchingSpells, function(a, b) return a.displayName < b.displayName end)

    local totalItems = #allMatchingSpells
    local totalPages = math.ceil(totalItems / pageSize)
    if page > totalPages and totalPages > 0 then page = totalPages end
    if page < 1 then page = 1 end

    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalItems)

    local spellsForPage = {}
    for i = startIndex, endIndex do
        local spell = allMatchingSpells[i]
        if spell then
            spellsForPage[spell.id] = spell
        end
    end

    return spellsForPage, totalItems, totalPages, page
end