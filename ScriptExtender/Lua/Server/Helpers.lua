function HLP.GetEntity(char)
    if type(char) ~= "string" then return char end 
    return Ext.Entity.Get(char)
end

function HLP.GetChar(char)
    if type(char) == "string" then return char end 
    return Ext.Entity.Get(char).Uuid.EntityUuid
end

function HLP.HasStatus(char, status)
    if Osi.HasAppliedStatus(char, status) == 1 then
        return true
    end
    if Osi.HasActiveStatus(char, status) == 1 then
        return true
    end

    return false
end

function HLP.GetAllChars()
    local allChars = {}
    local allEntities = Ext.Entity.GetAllEntitiesWithComponent("PartyMember")

    for _,entity in pairs(allEntities) do
        table.insert(allChars, HLP.GetChar(entity))
    end

    return allChars
end

function HLP.AllyChars(char, follower)
    Osi.SetFaction(char, Osi.GetFaction(follower))
end

function HLP.OnSameSide(char1, char2)
    return Osi.IsAlly(char1, char2)
    --return Osi.GetRelation(Osi.GetFaction(char1), Osi.GetFaction(char2)) == 0
end

function HLP.IsAlive(char)
    local entity = HLP.GetEntity(char)
    if not entity then return false end 

    return Osi.IsDead(char) == 0
end

function HLP.IsNPC(char)
    local char = HLP.GetChar(char)

    if Osi.IsPlayer(char) == 1 then return false end
    if HLP.Contains(HLP.Companions, char) == true then return false end 

    return true
end

function HLP.ToClient(event, payload, targetUuid)
    local clientId

    if type(targetUuid) == "number" then
        clientId = targetUuid
    else
        clientId = HLP.GetClientIdForEntity(targetUuid)

        if not clientId then
            return false
        end
    end

    event:SendToClient(payload, clientId)
    return true
end

--- Sends a message to a client after a specified delay in server ticks.
---@param event ExtNet.Channel The network channel to use.
---@param payload table The data to send.
---@param targetUuid string|number The target client's user ID or character UUID.
---@param delayTicks? number The number of ticks to wait (defaults to 10).
function HLP.ToClientDelayed(event, payload, targetUuid, delayTicks)
    delayTicks = delayTicks or 5
    local ticks = 0
    local e
    e = Ext.Events.Tick:Subscribe(function()
        ticks = ticks + 1
        if ticks >= delayTicks then
            HLP.ToClient(event, payload, targetUuid)
            Ext.Events.Tick:Unsubscribe(e)
        end
    end)
end

function HLP.GetClientIdForEntity(uuid)
    local entity = Ext.Entity.Get(uuid)
    if not entity then
        return nil
    end

    -- Check if entity has UserReservedFor component (for player avatars)
    if entity.UserReservedFor and entity.UserReservedFor.UserID then
        return entity.UserReservedFor.UserID
    end

    return nil
end

function HLP.Export(data, file)
    Ext.IO.SaveFile(file .. ".json", Ext.DumpExport(data))
end

function HLP.RefreshEquippedItem(character, itemTemplateUUID)
    local template = Ext.Template.GetTemplate(itemTemplateUUID)
    if not template or not template.Stats then return end
    local stats = Ext.Stats.Get(template.Stats)
    if not stats then return end
    
    local characterUUIDsToRefresh = {}
    if character then
        -- If a specific character is provided, ensure it's a UUID string
        local charUUID_str = (type(character) == "table" and character.uuid) or character
        table.insert(characterUUIDsToRefresh, charUUID_str)
    else
        -- If no specific character, refresh for all party members
        local allPartyMembersData = PARTY.GetMembers()
        for _, memberData in ipairs(allPartyMembersData) do
            table.insert(characterUUIDsToRefresh, memberData.uuid)
        end
    end

    for _, charUUID in ipairs(characterUUIDsToRefresh) do
        local slotsToCheck = { "Helmet", "Breast", "Gloves", "Boots", "Melee Main Weapon", "Melee Offhand Weapon", "Ranged Main Weapon", "Ranged Offhand Weapon", "Amulet", "Ring", "Ring2", "Underwear", "Cloak", "MusicalInstrument" }

        for _, slot in ipairs(slotsToCheck) do
            local itemHandle = Osi.GetEquippedItem(charUUID, slot)
            if itemHandle ~= 0 then
                local item = Ext.Entity.Get(itemHandle)
                if item and item.GameObjectVisual and item.GameObjectVisual.RootTemplateId == itemTemplateUUID then
                    Osi.Unequip(charUUID, itemHandle)
                    local ticks = 0
                    local e
                    e = Ext.Events.Tick:Subscribe(function()
                        ticks = ticks + 1
                        if ticks >= 10 then
                            Osi.Equip(charUUID, itemHandle)
                            Ext.Events.Tick:Unsubscribe(e)
                        end
                    end
                    )                
                end
            end
        end
    end
end

--- A wrapper for Ext.Loca.GetTranslatedString that falls back to a provided name if the result is an empty/placeholder string.
---@param handle string The localization handle.
---@param fallbackName string The name to use if the translation is missing.
---@return string The translated string or the fallback name.
function HLP.GetTranslatedString(handle, fallbackName)
    local translated = Ext.Loca.GetTranslatedString(handle, fallbackName)
    if not translated or translated == "" or translated == " " or string.sub(translated, 1, 3) == "%%%" then
        return fallbackName
    end
    return translated
end

--- A generic helper to manage semicolon-separated stat lists on item instances (e.g., PassivesOnEquip, StatusOnEquip).
--- It creates a unique stats object for the item instance if one doesn't exist.
---@param itemInstanceUUID string The UUID of the item instance to modify.
---@param templateUUID string The template UUID of the item, used to find the base stats.
---@param statId string The ID of the passive or status to add/remove.
---@param statProperty string The name of the stats property to modify (e.g., "PassivesOnEquip").
---@param otherStatProperty string The name of the other property to check for cleanup (e.g., "StatusOnEquip").
---@param remove boolean If true, removes the statId; otherwise, adds it.
function HLP.ManageStatOnItem(itemInstanceUUID, templateUUID, statId, statProperty, otherStatProperty, remove)
    local item = Ext.Entity.Get(itemInstanceUUID)
    if not item then return end

    local template = Ext.Template.GetTemplate(templateUUID)
    if not template or not template.Stats then return end

    local originalStatsName = template.Stats
    local originalStats = Ext.Stats.Get(originalStatsName)
    if not originalStats then return end

    -- Create a unique stats object name for this specific item instance
    local instanceStatsName = originalStatsName .. "_UCT_" .. itemInstanceUUID
    local instanceStats = Ext.Stats.Get(instanceStatsName)

    -- If it doesn't exist, create it by copying the original
    if not instanceStats then
        if remove then return end -- Can't remove from a non-existent custom stat
        instanceStats = Ext.Stats.Create(instanceStatsName, originalStats.ModifierList, originalStatsName)
        if not instanceStats then return end -- Creation failed
    end

    local currentStats = HLP.GetAttr(instanceStats, statProperty) or ""
    local statExists = string.find(currentStats, statId, 1, true)

    if remove then
        if not statExists then return end -- Not found, nothing to do
        local items = {}
        for s in string.gmatch(currentStats, "([^;]+)") do
            if s ~= statId then
                table.insert(items, s)
            end
        end
        instanceStats[statProperty] = table.concat(items, ";")
    else
        if statExists then return end -- Already exists, nothing to do
        instanceStats[statProperty] = (currentStats == "" and statId) or (currentStats .. ";" .. statId)
    end

    -- Check if this was the last modification. If so, revert to original stats.
    local otherStats = HLP.GetAttr(instanceStats, otherStatProperty) or ""
    if instanceStats[statProperty] == "" and otherStats == "" then
        item.Data.StatsId = originalStatsName
    else
        item.Data.StatsId = instanceStatsName
    end

    instanceStats:Sync()
    item:Replicate("Data")
    HLP.RefreshEquippedItem(nil, templateUUID)
end

--- A generic helper to manage character stats that are applied/removed directly (e.g., Passives, Statuses, Tags).
---@param payload table The payload from the client.
---@param remove boolean If true, removes the stat; otherwise, adds it.
---@param modVarKey string The key in Ext.Vars for tracking (e.g., "AddedPassives").
---@param addFn function The function to call to add the stat to a character.
---@param removeFn function The function to call to remove the stat from a character.
---@param refreshTabName string The name of the UI tab to refresh.
function HLP.ManageCharacterStat(payload, remove, modVarKey, addFn, removeFn, refreshTabName)
    local uuid = payload.uuid
    local data = payload.data
    local character = payload.character

    if not character then return end
    
    if remove then
        removeFn(character, uuid)
    else
        addFn(character, uuid)
    end

    local trackedStats = Ext.Vars.GetModVariables(ModuleUUID)[modVarKey] or {}
    if not trackedStats[character] then trackedStats[character] = {} end

    if remove then
        trackedStats[character][uuid] = nil
    else
        trackedStats[character][uuid] = data
    end
    
    Ext.Vars.GetModVariables(ModuleUUID)[modVarKey] = trackedStats
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = refreshTabName }, payload.ID)
end

--- A generic helper to clear all boosts of a certain type for a character.
---@param payload table The payload from the client.
---@param modKey string The key in CharacterModifications for this type of boost (e.g., "abilities").
---@param refreshTabName string The name of the UI tab to refresh.
function HLP.ClearAllCharacterBoosts(payload, modKey, refreshTabName)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] or not mods[character][modKey] then return end

    local boostMods = mods[character][modKey]
    for _, boostData in pairs(boostMods) do
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
        end
    end

    mods[character][modKey] = nil
    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = refreshTabName }, payload.ID)
end

--- A generic helper to manage character boosts that are applied/removed via Osi.AddBoosts/RemoveBoosts.
---@param payload table The payload from the client.
---@param modKey string The key in CharacterModifications for this type of boost (e.g., "abilities").
---@param boostType string The type of boost for the boost string (e.g., "Ability", "Skill").
---@param nameKey string The key in the payload for the name of the stat (e.g., "abilityName").
---@param refreshTabName string The name of the UI tab to refresh.
function HLP.ManageCharacterBoost(payload, modKey, boostType, nameKey, refreshTabName)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character][modKey] then mods[character][modKey] = {} end

    if payload.remove then
        local boostData = mods[character][modKey][payload.uuid]
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
            mods[character][modKey][payload.uuid] = nil
            Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        end
    else
        local name = payload[nameKey]
        local amount = payload.amount
        if not name or not amount then return end

        local boostString = string.format("%s(%s,%d)", boostType, name, amount)
        Osi.AddBoosts(character, boostString, "", "")

        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        local dataToStore = { amount = amount, boostString = boostString }
        dataToStore[nameKey] = name
        mods[character][modKey][uniqueKey] = dataToStore
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    end
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = refreshTabName }, payload.ID)
end

function HLP.ManageCharacterStatForParty(payload, remove, modVarKey, addFn, removeFn, refreshTabName)
    local uuid = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local trackedStats = Ext.Vars.GetModVariables(ModuleUUID)[modVarKey] or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        if remove then
            removeFn(charUUID, uuid)
        else
            addFn(charUUID, uuid)
        end
        
        if not trackedStats[charUUID] then trackedStats[charUUID] = {} end
        
        if remove then
            trackedStats[charUUID][uuid] = nil
        else
            trackedStats[charUUID][uuid] = data
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID)[modVarKey] = trackedStats
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = refreshTabName }, payload.ID)
end