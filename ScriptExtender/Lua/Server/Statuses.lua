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
        local displayName = Ext.Loca.GetTranslatedString(handle)

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