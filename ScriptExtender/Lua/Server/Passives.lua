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

function PASSV.AddOnItem(itemInstanceUUID, templateUUID, passiveId)
    local item = Ext.Entity.Get(itemInstanceUUID)
    if not item then return end

    local originalStatsName = Ext.Template.GetTemplate(templateUUID).Stats
    local originalStats = Ext.Stats.Get(originalStatsName)
    if not originalStats then return end

    -- Create a unique stats object name for this specific item instance
    local instanceStatsName = originalStatsName .. "_UCT_" .. itemInstanceUUID
    local instanceStats = Ext.Stats.Get(instanceStatsName)

    -- If it doesn't exist, create it by copying the original
    if not instanceStats then
        instanceStats = Ext.Stats.Create(instanceStatsName, originalStats.ModifierList, originalStatsName)
        if not instanceStats then return end -- Creation failed
    end

    -- Add the new passive
    local passivesOnEquip = HLP.GetAttr(instanceStats, "PassivesOnEquip") or ""
    if string.find(passivesOnEquip, passiveId, 1, true) then
        return -- Passive already applied, do nothing.
    end

    passivesOnEquip = (passivesOnEquip == "" and passiveId) or (passivesOnEquip .. ";" .. passiveId)
    instanceStats.PassivesOnEquip = passivesOnEquip
    instanceStats:Sync()

    -- Apply the new stats object to the item instance and refresh it
    if item.Data.StatsId ~= instanceStatsName then
        item.Data.StatsId = instanceStatsName
        item:Replicate("Data")
    end

    HLP.RefreshEquippedItem(nil, templateUUID)
end

function PASSV.RemoveFromItem(itemInstanceUUID, templateUUID, passiveId)
    local item = Ext.Entity.Get(itemInstanceUUID)
    if not item then return end

    local originalStatsName = Ext.Template.GetTemplate(templateUUID).Stats
    local instanceStatsName = originalStatsName .. "_UCT_" .. itemInstanceUUID
    local instanceStats = Ext.Stats.Get(instanceStatsName)

    if not instanceStats then return end

    local passivesOnEquip = HLP.GetAttr(instanceStats, "PassivesOnEquip") or ""
    if not string.find(passivesOnEquip, passiveId, 1, true) then
        return -- Passive not found on this item
    end

    -- Remove the passive from the list
    local items = {}
    for p in string.gmatch(passivesOnEquip, "([^;]+)") do
        if p ~= passiveId then
            table.insert(items, p)
        end
    end
    instanceStats.PassivesOnEquip = table.concat(items, ";")

    -- Check if this was the last modification. If so, revert to original stats.
    local statusesOnEquip = HLP.GetAttr(instanceStats, "StatusOnEquip") or ""
    if instanceStats.PassivesOnEquip == "" and statusesOnEquip == "" then
        item.Data.StatsId = originalStatsName
    end

    instanceStats:Sync()
    item:Replicate("Data")
    HLP.RefreshEquippedItem(nil, templateUUID)
end

function PASSV.Manage(payload)
    local uuid = payload.uuid
    local data = payload.data
    local character = payload.character
    local remove = HLP.GetAttr(payload, "remove")

    if not character then return end
    
    PASSV.Add(character, uuid, remove)

    local passives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}
    if not passives[character] then passives[character] = {} end

    if remove then
        passives[character][uuid] = nil
    else
        passives[character][uuid] = data
    end
    
    Ext.Vars.GetModVariables(ModuleUUID).AddedPassives = passives
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
end

function PASSV.ManageForParty(payload, remove)
    local uuid = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local passives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        PASSV.Add(charUUID, uuid, remove)
        if not passives[charUUID] then passives[charUUID] = {} end
        
        if remove then
            passives[charUUID][uuid] = nil
        else
            passives[charUUID][uuid] = data
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).AddedPassives = passives
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
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
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
end