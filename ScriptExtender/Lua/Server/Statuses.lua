STAT = {}
STAT.Max = 50

function STAT.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = STAT.Max

    local itemData = Ext.Stats.GetStats("StatusData")

    local allMatchingStatuses = {}

    for k,v in pairs(itemData) do 
        local id = v
        v = Ext.Stats.Get(v)
        local icon = HLP.GetAttr(v, "Icon")
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
            })
        end
    end

    table.sort(allMatchingStatuses, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingStatuses, page, pageSize)
end

function STAT.Apply(char, statusId, remove)
    if remove then
        Osi.RemoveStatus(char, statusId)
    else
        Osi.ApplyStatus(char, statusId, -1, 1)
    end
end

function STAT.ApplyToItem(itemTemplateUUID, statusId)
    local template = Ext.Template.GetTemplate(itemTemplateUUID)
    if not template or not template.Stats then return end
    
    local originalStats = Ext.Stats.Get(template.Stats)
    if not originalStats then return end

    local backupStatsName = originalStats.Name .. "_UCT_BACKUP"
    local backupStats = Ext.Stats.Get(backupStatsName)

    if not backupStats then
        local modifierList = originalStats.ModifierList
        if modifierList == "Weapon" or modifierList == "Armor" then
            backupStats = Ext.Stats.Create(backupStatsName, modifierList, originalStats.Name)
            if not backupStats then return end
        else
            return
        end
    end
 
    local statusOnEquip = HLP.GetAttr(originalStats, "StatusOnEquip") or ""
    if not string.find(statusOnEquip, statusId, 1, true) then
        statusOnEquip = (statusOnEquip == "" and statusId) or (statusOnEquip .. ";" .. statusId)
        originalStats.StatusOnEquip = statusOnEquip
        originalStats:Sync()
        HLP.RefreshEquippedItem(nil, itemTemplateUUID)
    end
end

function STAT.RemoveFromItem(itemTemplateUUID, statusId)
    local template = Ext.Template.GetTemplate(itemTemplateUUID)
    if not template or not template.Stats then return end

    local originalStats = Ext.Stats.Get(template.Stats)
    if not originalStats then return end

    local backupStatsName = originalStats.Name .. "_UCT_BACKUP"
    local backupStats = Ext.Stats.Get(backupStatsName)

    if not backupStats then return end

    local statusOnEquip = HLP.GetAttr(originalStats, "StatusOnEquip") or ""
    if not string.find(statusOnEquip, statusId, 1, true) then
        return
    end

    local items = {}
    for item in string.gmatch(statusOnEquip, "([^;]+)") do
        if item ~= statusId then
            table.insert(items, item)
        end
    end

    local newStatuses = table.concat(items, ";")
    originalStats.StatusOnEquip = newStatuses
    
    local currentPassives = HLP.GetAttr(originalStats, "PassivesOnEquip") or ""
    local backupPassives = HLP.GetAttr(backupStats, "PassivesOnEquip") or ""
    local backupStatuses = HLP.GetAttr(backupStats, "StatusOnEquip") or ""

    if newStatuses == backupStatuses and currentPassives == backupPassives then
        originalStats.PassivesOnEquip = backupStats.PassivesOnEquip
        originalStats.StatusOnEquip = backupStats.StatusOnEquip
    end

    originalStats:Sync()
    HLP.RefreshEquippedItem(nil, itemTemplateUUID)
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
    local itemTemplateUUID = payload.itemTemplateUUID
    local statusUUID = payload.statusUUID
    local data = payload.data

    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not modifiedEquipment[itemTemplateUUID] then modifiedEquipment[itemTemplateUUID] = {} end
    if not modifiedEquipment[itemTemplateUUID].statuses then modifiedEquipment[itemTemplateUUID].statuses = {} end

    if remove then
        STAT.RemoveFromItem(itemTemplateUUID, statusUUID)
        modifiedEquipment[itemTemplateUUID].statuses[statusUUID] = nil
        if HLP.Count(modifiedEquipment[itemTemplateUUID].statuses) == 0 then
            modifiedEquipment[itemTemplateUUID].statuses = nil
        end
        if HLP.Count(modifiedEquipment[itemTemplateUUID]) == 0 then
            modifiedEquipment[itemTemplateUUID] = nil
        end
    else
        STAT.ApplyToItem(itemTemplateUUID, statusUUID)
        modifiedEquipment[itemTemplateUUID].statuses[statusUUID] = data
    end

    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
end