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
        local useCosts = HLP.GetAttr(v, "UseCosts")
        local level = HLP.GetAttr(v, "Level")
        local cooldown = HLP.GetAttr(v, "Cooldown")

        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "unknown" then
            table.insert(allMatchingSpells, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
                useCosts = useCosts,
                level = level,
                cooldown = cooldown
            })
        end
    end

    table.sort(allMatchingSpells, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingSpells, page, pageSize)
end

function SPLL.Learn(character, spellId, unlearn)
    if unlearn then
        Osi.RemoveSpell(character, spellId, 1)
    else
        Osi.AddSpell(character, spellId, 1, 1)
    end
end