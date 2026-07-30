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

        local description = Ext.Loca.GetTranslatedString(HLP.GetAttr(v, "Description"))
        local boosts = HLP.GetAttr(v, "Boosts")
        local conditions = HLP.GetAttr(v, "Conditions")

        local modId = HLP.GetAttr(v, "ModId")
        local mod = Ext.Mod.GetMod(modId)
        local modName = mod ~= nil and mod.Info ~= nil and mod.Info.Name ~= nil and mod.Info.Name or "Unknown"

        local displayName = Ext.Loca.GetTranslatedString(handle)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName))

        if matchesSearch and displayName and displayName ~= "" then
            table.insert(allMatchingPassives, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
                description = description,
                boosts = boosts,
                conditions = conditions,
                modName = modName
            })
        end
    end

    table.sort(allMatchingPassives, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingPassives, page, pageSize)
end

function PASSV.Learn(character, passiveId, unlearn)
    if unlearn then
        Osi.RemovePassive(character, passiveId)
    else
        Osi.AddPassive(character, passiveId)
    end
end

function PASSV.LearnOnWeapon(character, passiveId)
    local weaponHandle = Osi.GetEquippedWeapon(character)
    if weaponHandle ~= 0 then
        local weapon = Ext.Entity.Get(weaponHandle)
        if weapon and weapon.Uuid then
            local weaponGuid = weapon.Uuid.EntityUuid
            Osi.AddPassive(weaponGuid, passiveId)
        end
    end
end