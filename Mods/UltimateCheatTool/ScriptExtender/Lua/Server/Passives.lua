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

function PASSV.LearnOnItem(character, itemTemplateUUID, passiveId)
    local template = Ext.Template.GetTemplate(itemTemplateUUID)
    if not template or not template.Stats then return end
    local stats = Ext.Stats.Get(template.Stats)
    if not stats then return end

    local passivesOnEquip = HLP.GetAttr(stats, "PassivesOnEquip") or ""
    if not string.find(passivesOnEquip, passiveId, 1, true) then
        passivesOnEquip = (passivesOnEquip == "" and passiveId) or (passivesOnEquip .. ";" .. passiveId)
        stats.PassivesOnEquip = passivesOnEquip
        stats:Sync()
    end
end

function PASSV.UnlearnOnItem(itemTemplateUUID, passiveId)
    local template = Ext.Template.GetTemplate(itemTemplateUUID)
    if not template or not template.Stats then return end
    local stats = Ext.Stats.Get(template.Stats)
    if not stats then return end

    local passivesOnEquip = HLP.GetAttr(stats, "PassivesOnEquip") or ""
    if passivesOnEquip == "" then return end

    local items = {}
    local found = false
    for item in string.gmatch(passivesOnEquip, "([^;]+)") do
        if item ~= passiveId then
            table.insert(items, item)
        else
            found = true
        end
    end

    if found then
        stats.PassivesOnEquip = table.concat(items, ";")
        stats:Sync()
    end
end