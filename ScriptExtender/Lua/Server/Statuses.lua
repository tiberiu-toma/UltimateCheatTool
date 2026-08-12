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
        local displayName = HLP.GetTranslatedString(handle, name)

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
    local item = Ext.Entity.Get(itemInstanceUUID)
    if not item then return end

    local originalStatsName = Ext.Template.GetTemplate(templateUUID).Stats
    local originalStats = Ext.Stats.Get(originalStatsName)
    if not originalStats then return end

    local instanceStatsName = originalStatsName .. "_UCT_" .. itemInstanceUUID
    local instanceStats = Ext.Stats.Get(instanceStatsName)

    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    local itemModEntry = modifiedEquipment[itemInstanceUUID]

    -- If a custom stats object exists, check if its PassivesOnEquip/StatusOnEquip need to be cleared.
    -- This prevents stale data from previous save sessions from reappearing.
    if instanceStats then
        -- Clear StatusOnEquip if no equip statuses are tracked for this item in the current save
        if not itemModEntry or not itemModEntry.statuses or HLP.Count(itemModEntry.statuses) == 0 then
            instanceStats.StatusOnEquip = ""
        end
        -- Clear PassivesOnEquip if no equip passives are tracked for this item in the current save
        if not itemModEntry or not itemModEntry.passives or HLP.Count(itemModEntry.passives) == 0 then
            instanceStats.PassivesOnEquip = ""
        end
    end
    
    if not instanceStats then
        instanceStats = Ext.Stats.Create(instanceStatsName, originalStats.ModifierList, originalStatsName)
        if not instanceStats then return end
    end

    local statusOnEquip = HLP.GetAttr(instanceStats, "StatusOnEquip") or ""
    if string.find(statusOnEquip, statusId, 1, true) then
        return -- Status already applied, do nothing.
    end

    statusOnEquip = (statusOnEquip == "" and statusId) or (statusOnEquip .. ";" .. statusId)
    instanceStats.StatusOnEquip = statusOnEquip
    instanceStats:Sync()

    if item.Data.StatsId ~= instanceStatsName then
        item.Data.StatsId = instanceStatsName
        item:Replicate("Data")
    end

    HLP.RefreshEquippedItem(nil, templateUUID)
end

function STAT.RemoveFromItem(itemInstanceUUID, templateUUID, statusId)
    local item = Ext.Entity.Get(itemInstanceUUID)
    if not item then return end

    local originalStatsName = Ext.Template.GetTemplate(templateUUID).Stats
    local instanceStatsName = originalStatsName .. "_UCT_" .. itemInstanceUUID
    local instanceStats = Ext.Stats.Get(instanceStatsName)

    if not instanceStats then return end

    local statusOnEquip = HLP.GetAttr(instanceStats, "StatusOnEquip") or ""
    if not string.find(statusOnEquip, statusId, 1, true) then
        return
    end

    local items = {}
    for s in string.gmatch(statusOnEquip, "([^;]+)") do
        if s ~= statusId then
            table.insert(items, s)
        end
    end
    instanceStats.StatusOnEquip = table.concat(items, ";")

    local passivesOnEquip = HLP.GetAttr(instanceStats, "PassivesOnEquip") or ""
    if instanceStats.StatusOnEquip == "" and passivesOnEquip == "" then
        item.Data.StatsId = originalStatsName
    end

    instanceStats:Sync()
    item:Replicate("Data")
    HLP.RefreshEquippedItem(nil, templateUUID)
end

function STAT.Manage(payload)
    local uuid = payload.uuid
    local data = payload.data
    local character = payload.character
    local remove = HLP.GetAttr(payload, "remove")

    if not character then return end
    
    STAT.Apply(character, uuid, remove)

    local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
    if not statuses[character] then statuses[character] = {} end

    if remove then
        statuses[character][uuid] = nil
    else
        statuses[character][uuid] = data
    end
    
    Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
end

function STAT.ManageForParty(payload, remove)
    local uuid = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        STAT.Apply(charUUID, uuid, remove)
        if not statuses[charUUID] then statuses[charUUID] = {} end
        
        if remove then
            statuses[charUUID][uuid] = nil
        else
            statuses[charUUID][uuid] = data
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
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