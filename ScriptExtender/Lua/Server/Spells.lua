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
        
        local spellType = HLP.GetAttr(v, "SpellType")
        local spellSchool = HLP.GetAttr(v, "SpellSchool")
        local useCosts = HLP.GetAttr(v, "UseCosts")
        local level = HLP.GetAttr(v, "Level")
        local cooldown = HLP.GetAttr(v, "Cooldown")

        local modId = HLP.GetAttr(v, "ModId")
        local mod = Ext.Mod.GetMod(modId)
        local modName = mod ~= nil and mod.Info ~= nil and mod.Info.Name ~= nil and mod.Info.Name or "Unknown"

        local displayName = HLP.GetTranslatedString(handle, name)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "unknown" then
            table.insert(allMatchingSpells, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
                spellType = spellType,
                spellSchool = spellSchool,
                useCosts = useCosts,
                level = level,
                cooldown = cooldown,
                modName = modName
            })
        end
    end

    table.sort(allMatchingSpells, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingSpells, page, pageSize)
end