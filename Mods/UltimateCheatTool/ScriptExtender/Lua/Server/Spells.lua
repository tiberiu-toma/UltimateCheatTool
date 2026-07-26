SPLL = {}
SPLL.Max = 50000

function SPLL.GetAll(search)
    search = search or ""

    local itemData = Ext.Stats.GetStats("SpellData")

    local spellCount = 0
    local spells = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName")

        local displayName = Ext.Loca.GetTranslatedString(handle, name)

        local matchesSearch = true

        if search ~= "" then
            matchesSearch = HLP.StrContains(search, name) or HLP.StrContains(search, displayName)
        end

        if matchesSearch then

            local isSpell = true

            if isSpell then
                spellCount = spellCount + 1
                
                spells[id] = {
                    id = id,
                    name = name,
                    icon = icon,
                    displayName = displayName
                }
            end
        end
            
        if HLP.Count(spells) >= SPLL.Max then break end 
    end

    return spells
end