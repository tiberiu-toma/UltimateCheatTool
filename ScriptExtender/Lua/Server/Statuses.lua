STAT = {}
STAT.Max = 50

function STAT.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = STAT.Max

    local itemData = Ext.Stats.GetStats("StatusData")

    local allMatchingStatuses = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")

        local modId = HLP.GetAttr(v, "ModId")
        local mod = Ext.Mod.GetMod(modId)
        local modName = mod ~= nil and mod.Info ~= nil and mod.Info.Name ~= nil and mod.Info.Name or "Unknown"

        local name = HLP.GetAttr(v, "Name")
        local handle = HLP.GetAttr(v, "DisplayName") 
        local displayName = handle ~= nil and handle ~= "" and HLP.GetTranslatedString(handle, name) or name

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName))

        if matchesSearch and displayName and displayName ~= "" and icon and icon ~= "" then
            table.insert(allMatchingStatuses, {
                id = id,
                name = name,
                icon = icon,
                displayName = displayName,
                modName = modName
            })
        end
    end

    local filtered = FLTR.Apply(allMatchingStatuses, filters)
    table.sort(filtered, function(a, b) return a.displayName < b.displayName end)
    return UTL.Paginate(filtered, page, pageSize)
end

function STAT.Apply(char, statusId, remove)
    if remove then
        Osi.RemoveStatus(char, statusId)
    else
        Osi.ApplyStatus(char, statusId, -1, 1)
    end
end

function STAT.ApplyToItem(itemInstanceUUID, templateUUID, statusId)
    HLP.ManageStatOnItem(itemInstanceUUID, templateUUID, statusId, "StatusOnEquip", "PassivesOnEquip", false)
end

function STAT.RemoveFromItem(itemInstanceUUID, templateUUID, statusId)
    HLP.ManageStatOnItem(itemInstanceUUID, templateUUID, statusId, "StatusOnEquip", "PassivesOnEquip", true)
end

function STAT.Manage(payload)
    local remove = HLP.GetAttr(payload, "remove")
    HLP.ManageCharacterStat(payload, remove, "AppliedStatuses", STAT.Apply, Osi.RemoveStatus, "Status")
end

function STAT.ManageForParty(payload, remove)
    HLP.ManageCharacterStatForParty(payload, remove, "AppliedStatuses", STAT.Apply, Osi.RemoveStatus, "Status")
end

function STAT.ManageOnItem(payload, remove)
    local itemInstanceUUID = payload.itemInstanceUUID
    local templateUUID = payload.templateUUID
    local statusUUID = payload.statusUUID
    local data = payload.data

    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not modifiedEquipment[itemInstanceUUID] then modifiedEquipment[itemInstanceUUID] = {} end
    if not modifiedEquipment[itemInstanceUUID].statuses then modifiedEquipment[itemInstanceUUID].statuses = {} end

    if remove then
        STAT.RemoveFromItem(itemInstanceUUID, templateUUID, statusUUID)
        modifiedEquipment[itemInstanceUUID].statuses[statusUUID] = nil
        if HLP.Count(modifiedEquipment[itemInstanceUUID].statuses) == 0 then
            modifiedEquipment[itemInstanceUUID].statuses = nil
        end
        if HLP.Count(modifiedEquipment[itemInstanceUUID]) == 0 then
            modifiedEquipment[itemInstanceUUID] = nil
        end
    else
        STAT.ApplyToItem(itemInstanceUUID, templateUUID, statusUUID)
        modifiedEquipment[itemInstanceUUID].statuses[statusUUID] = data
        modifiedEquipment[itemInstanceUUID].templateUUID = templateUUID
    end

    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID, 20)
end

function STAT.ManageDirectOnItem(payload, remove)
    local itemInstanceUUID = payload.itemInstanceUUID
    if not itemInstanceUUID then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not mods[itemInstanceUUID] then mods[itemInstanceUUID] = {} end
    if not mods[itemInstanceUUID].directStatuses then mods[itemInstanceUUID].directStatuses = {} end

    local statusUUID = payload.statusUUID
    if not statusUUID then return end

    if remove then
        Osi.RemoveStatus(itemInstanceUUID, statusUUID)
        mods[itemInstanceUUID].directStatuses[statusUUID] = nil
    else
        -- Apply status with infinite duration
        Osi.ApplyStatus(itemInstanceUUID, statusUUID, -1, 1)
        mods[itemInstanceUUID].directStatuses[statusUUID] = {
            data = payload.data
        }
        -- Store template UUID for re-application logic
        mods[itemInstanceUUID].templateUUID = payload.templateUUID
    end

    -- Cleanup logic
    if HLP.Count(mods[itemInstanceUUID].directStatuses) == 0 then
        mods[itemInstanceUUID].directStatuses = nil
    end
    if HLP.Count(mods[itemInstanceUUID]) == 0 then
        mods[itemInstanceUUID] = nil
    end

    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
end