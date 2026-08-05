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

function PASSV.Add(character, passiveId, remove)
    if remove then
        Osi.RemovePassive(character, passiveId)
    else
        Osi.AddPassive(character, passiveId)
    end
end

function PASSV.AddOnItem(itemTemplateUUID, passiveId)
    local template = Ext.Template.GetTemplate(itemTemplateUUID)
    if not template or not template.Stats then return end
    
    local originalStats = Ext.Stats.Get(template.Stats)
    if not originalStats then return end
    
    local backupStatsName = originalStats.Name .. "_UCT_BACKUP"
    local backupStats = Ext.Stats.Get(backupStatsName)

    -- If a backup doesn't exist, create one before modifying the original.
    if not backupStats then
        local modifierList = originalStats.ModifierList
        if modifierList == "Weapon" or modifierList == "Armor" then
            -- Create a backup copy of the original stats.
            backupStats = Ext.Stats.Create(backupStatsName, modifierList, originalStats.Name)
            if not backupStats then return end -- Backup creation failed
        else
            return -- Not a modifiable item type
        end
    end
 
    local passivesOnEquip = HLP.GetAttr(originalStats, "PassivesOnEquip") or ""
    if not string.find(passivesOnEquip, passiveId, 1, true) then
        passivesOnEquip = (passivesOnEquip == "" and passiveId) or (passivesOnEquip .. ";" .. passiveId)
        originalStats.PassivesOnEquip = passivesOnEquip
        originalStats:Sync()

        HLP.RefreshEquippedItem(nil, itemTemplateUUID)
    end
end

function PASSV.RemoveFromItem(itemTemplateUUID, passiveId)
    local template = Ext.Template.GetTemplate(itemTemplateUUID)
    if not template or not template.Stats then return end

    local originalStats = Ext.Stats.Get(template.Stats)
    if not originalStats then return end

    local backupStatsName = originalStats.Name .. "_UCT_BACKUP"
    local backupStats = Ext.Stats.Get(backupStatsName)

    -- If there's no backup, we can't (and shouldn't) do anything.
    if not backupStats then return end

    local passivesOnEquip = HLP.GetAttr(originalStats, "PassivesOnEquip") or ""
    if not string.find(passivesOnEquip, passiveId, 1, true) then
        return -- Passive not found on this item
    end

    local items = {}
    for item in string.gmatch(passivesOnEquip, "([^;]+)") do
        if item ~= passiveId then
            table.insert(items, item)
        end
    end

    local newPassives = table.concat(items, ";")
    originalStats.PassivesOnEquip = newPassives

    -- Check if this was the last modification. If so, revert to original stats.
    local currentStatuses = HLP.GetAttr(originalStats, "StatusOnEquip") or ""
    local backupPassives = HLP.GetAttr(backupStats, "PassivesOnEquip") or ""
    local backupStatuses = HLP.GetAttr(backupStats, "StatusOnEquip") or ""

    if newPassives == backupPassives and currentStatuses == backupStatuses then
        -- All custom modifications are gone. Restore the original properties.
        originalStats.PassivesOnEquip = backupStats.PassivesOnEquip
        originalStats.StatusOnEquip = backupStats.StatusOnEquip
    end

    originalStats:Sync()
    HLP.RefreshEquippedItem(nil, itemTemplateUUID)
end