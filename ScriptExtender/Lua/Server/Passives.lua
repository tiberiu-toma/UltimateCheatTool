PASSV = {}
PASSV.Max = 50

function PASSV.GetAll(search, page, filters)
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

        local displayName = HLP.GetTranslatedString(handle, name)

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

    local filtered = FLTR.Apply(allMatchingPassives, filters)
    table.sort(filtered, function(a, b) return a.displayName < b.displayName end)
    return UTL.Paginate(filtered, page, pageSize)
end

function PASSV.Add(character, passiveId, remove)
    if remove then
        Osi.RemovePassive(character, passiveId)
    else
        Osi.AddPassive(character, passiveId)
    end
end

function PASSV.AddOnItem(itemInstanceUUID, templateUUID, passiveId)
    HLP.ManageStatOnItem(itemInstanceUUID, templateUUID, passiveId, "PassivesOnEquip", "StatusOnEquip", false)
end

function PASSV.RemoveFromItem(itemInstanceUUID, templateUUID, passiveId)
    HLP.ManageStatOnItem(itemInstanceUUID, templateUUID, passiveId, "PassivesOnEquip", "StatusOnEquip", true)
end

function PASSV.Manage(payload)
    local remove = HLP.GetAttr(payload, "remove")
    HLP.ManageCharacterStat(payload, remove, "AddedPassives", PASSV.Add, Osi.RemovePassive, "Passive")
end

function PASSV.ManageForParty(payload, remove)
    HLP.ManageCharacterStatForParty(payload, remove, "AddedPassives", PASSV.Add, Osi.RemovePassive, "Passive")
end

function PASSV.ManageOnItem(payload, remove)
    local itemInstanceUUID = payload.itemInstanceUUID
    local templateUUID = payload.templateUUID
    local passiveUUID = payload.passiveUUID
    local data = payload.data

    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not modifiedEquipment[itemInstanceUUID] then modifiedEquipment[itemInstanceUUID] = {} end
    if not modifiedEquipment[itemInstanceUUID].passives then modifiedEquipment[itemInstanceUUID].passives = {} end

    if remove then
        PASSV.RemoveFromItem(itemInstanceUUID, templateUUID, passiveUUID)
        modifiedEquipment[itemInstanceUUID].passives[passiveUUID] = nil
        if HLP.Count(modifiedEquipment[itemInstanceUUID].passives) == 0 then
            modifiedEquipment[itemInstanceUUID].passives = nil
        end
        if HLP.Count(modifiedEquipment[itemInstanceUUID]) == 0 then
            modifiedEquipment[itemInstanceUUID] = nil
        end
    else
        PASSV.AddOnItem(itemInstanceUUID, templateUUID, passiveUUID)
        modifiedEquipment[itemInstanceUUID].passives[passiveUUID] = data
        modifiedEquipment[itemInstanceUUID].templateUUID = templateUUID
    end

    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID, 20)
end

function PASSV.ManageDirectOnItem(payload, remove)
    local itemInstanceUUID = payload.itemInstanceUUID
    if not itemInstanceUUID then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not mods[itemInstanceUUID] then mods[itemInstanceUUID] = {} end
    if not mods[itemInstanceUUID].directPassives then mods[itemInstanceUUID].directPassives = {} end

    local passiveUUID = payload.passiveUUID
    if not passiveUUID then return end

    if remove then
        Osi.RemovePassive(itemInstanceUUID, passiveUUID)
        mods[itemInstanceUUID].directPassives[passiveUUID] = nil
    else
        Osi.AddPassive(itemInstanceUUID, passiveUUID)
        mods[itemInstanceUUID].directPassives[passiveUUID] = {
            data = payload.data
        }
        -- Store template UUID for re-application logic
        mods[itemInstanceUUID].templateUUID = payload.templateUUID
    end

    -- Cleanup logic
    if HLP.Count(mods[itemInstanceUUID].directPassives) == 0 then
        mods[itemInstanceUUID].directPassives = nil
    end
    if HLP.Count(mods[itemInstanceUUID]) == 0 then
        mods[itemInstanceUUID] = nil
    end

    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
end