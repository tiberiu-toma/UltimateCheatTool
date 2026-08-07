local RSRC = Ext.Require("Server/Resources.lua")

--- Creates a generic handler for fetching paginated data from a module and sending it to the client.
---@param dataModule table The data module with a `GetAll(search, page)` function.
---@param sendMessage ExtNet.Channel The network channel to send the response on.
---@return function
local function CreateFetchHandler(dataModule, sendMessage)
    return function(payload)
        local search = HLP.GetAttr(payload, "search") or ""
        local page = HLP.GetAttr(payload, "page") or 1

        local items, totalItems, totalPages, currentPage = dataModule.GetAll(search, page)

        HLP.ToClient(
            sendMessage,
            {
                data = items,
                totalItems = totalItems,
                totalPages = totalPages,
                currentPage = currentPage
            },
            payload.ID
        )
    end
end

SMS.FetchEquipment:SetHandler(CreateFetchHandler(EKP, SMS.SendEquipment))
SMS.FetchNPCs:SetHandler(CreateFetchHandler(ENPC, SMS.SendNPCs))
SMS.FetchSpells:SetHandler(CreateFetchHandler(SPLL, SMS.SendSpells))
SMS.FetchResources:SetHandler(CreateFetchHandler(RSRC, SMS.SendResources))
SMS.FetchWaypoints:SetHandler(CreateFetchHandler(TELP, SMS.SendWaypoints))
SMS.FetchConsumables:SetHandler(CreateFetchHandler(CONS, SMS.SendConsumables))
SMS.FetchPassives:SetHandler(CreateFetchHandler(PASSV, SMS.SendPassives))
SMS.FetchStatuses:SetHandler(CreateFetchHandler(STAT, SMS.SendStatuses))
SMS.FetchTags:SetHandler(CreateFetchHandler(TAGS, SMS.SendTags))

SMS.LearnSpell:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    local character = payload.character
    local ability = payload.ability or "Wisdom" -- Default to Wisdom if not provided

    if not character then return end
    
    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].spells then mods[character].spells = {} end

    if HLP.GetAttr(payload, "unlearn") then
        local spellData = mods[character].spells[uuid]
        if spellData then
            local boostString = string.format("UnlockSpell(%s,%s,%s,,%s)", spellData.spellName, spellData.learningStrategy, "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", spellData.castingAbility)
            Osi.RemoveBoosts(character, boostString, 1, "", "")
            mods[character].spells[uuid] = nil
            Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
            HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Spell" }, payload.ID)
        end
    else
        local learningStrategy = "AddChildren"
        local boostString = string.format("UnlockSpell(%s,%s,%s,,%s)", uuid, learningStrategy, "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", ability)
        Osi.AddBoosts(character, boostString, "", "")

        mods[character].spells[uuid] = {
            spellName = uuid,
            learningStrategy = learningStrategy,
            castingAbility = ability,
            data = data
        }
        
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Spell" }, payload.ID)
    end
end)

SMS.ManageResource:SetHandler(function(payload)
    local resourceId = payload.uuid -- This will be the resource name/id
    local data = payload.data
    local character = payload.character
    local amount = payload.amount or 1 -- Default to 1 if not provided
    local level = payload.level or 0   -- Default to 0 if not provided

    -- When adding, resourceId is the base name (e.g., "ActionPoint").
    -- When removing, payload.uuid will be the full boostString (e.g., "ActionResource(ActionPoint,1,0)").
    local currentBoostString = string.format("ActionResource(%s,%s,%s)", resourceId, amount, level)

    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].resources then mods[character].resources = {} end

    if HLP.GetAttr(payload, "remove") then
        -- When removing, payload.uuid is the unique key
        local resourceData = mods[character].resources[payload.uuid]
        if resourceData and resourceData.boostString then
            -- Use the stored boostString for removal
            Osi.RemoveBoosts(character, resourceData.boostString, 1, "", "")
            mods[character].resources[payload.uuid] = nil
        else
            -- Fallback for old format or if something went wrong.
            Osi.RemoveBoosts(character, payload.uuid, 1, "", "")
            if mods[character].resources[payload.uuid] then
                mods[character].resources[payload.uuid] = nil
            end
        end
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Resource" }, payload.ID)
    else
        Osi.AddBoosts(character, currentBoostString, "", "")

        -- Generate a truly unique key for this instance to allow duplicates
        local uniqueKey = currentBoostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[character].resources[uniqueKey] = { id = resourceId, name = data.name, displayName = data.displayName, description = data.description, amount = amount, level = level, maxLevel = data.maxLevel, boostString = currentBoostString }

        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Resource" }, payload.ID)
    end
end)

SMS.AddResourceForParty:SetHandler(function(payload)
    local resourceId = payload.uuid
    local data = payload.data
    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local amount = payload.amount or 1 -- Default to 1 if not provided
    local level = payload.level or 0   -- Default to 0 if not provided

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local boostString = string.format("ActionResource(%s,%s,%s)", resourceId, amount, level)

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        Osi.AddBoosts(charUUID, boostString, "", "")
        if not mods[charUUID] then mods[charUUID] = {} end
        if not mods[charUUID].resources then mods[charUUID].resources = {} end

        -- Generate a unique key for each character for this instance
        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[charUUID].resources[uniqueKey] = { id = resourceId, name = data.name, displayName = data.displayName, description = data.description, amount = amount, level = level, maxLevel = data.maxLevel, boostString = boostString }
    end

    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Resource" }, payload.ID)
end)

SMS.RemoveResourceForParty:SetHandler(function(payload)
    local resourceId = payload.uuid -- This is the base resource name, e.g., "ActionPoint"

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        if mods[charUUID] and mods[charUUID].resources then
            local resourcesForChar = mods[charUUID].resources
            local keysToRemove = {}
            for key, resourceData in pairs(resourcesForChar) do
                if resourceData.id == resourceId then
                    Osi.RemoveBoosts(charUUID, resourceData.boostString, 1, "", "")
                    table.insert(keysToRemove, key)
                end
            end
            for _, key in ipairs(keysToRemove) do
                resourcesForChar[key] = nil
            end
        end
    end
    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Resource" }, payload.ID)
end)

SMS.FetchAbilities:SetHandler(function(payload)
    local charUUID = payload.character
    if not charUUID then return end

    local abilities = {"Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma"}
    local abilityScores = {}

    for _, ability in ipairs(abilities) do
        abilityScores[ability] = Osi.GetAbility(charUUID, ability)
    end

    HLP.ToClient(
        SMS.SendAbilities,
        {
            character = charUUID,
            scores = abilityScores
        },
        payload.ID
    )
end)

SMS.ClearAllAbilityBoosts:SetHandler(function(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] or not mods[character].abilities then return end

    local abilityMods = mods[character].abilities
    for _, boostData in pairs(abilityMods) do
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
        end
    end

    mods[character].abilities = nil
    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Ability" }, payload.ID)
end)

SMS.ManageAbility:SetHandler(function(payload)
    local character = payload.character
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].abilities then mods[character].abilities = {} end

    if payload.remove then
        -- The payload.uuid is the unique key for the boost to remove
        local boostData = mods[character].abilities[payload.uuid]
        if boostData and boostData.boostString then
            Osi.RemoveBoosts(character, boostData.boostString, 1, "", "")
            mods[character].abilities[payload.uuid] = nil
            Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
            HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Ability" }, payload.ID)
        end
    else
        local abilityName = payload.abilityName
        local amount = payload.amount
        if not abilityName or not amount then return end

        local boostString = string.format("Ability(%s,%d)", abilityName, amount)
        Osi.AddBoosts(character, boostString, "", "")

        -- Generate a unique key to allow multiple boosts of the same type
        local uniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        
        mods[character].abilities[uniqueKey] = { abilityName = abilityName, amount = amount, boostString = boostString }
        
        Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Ability" }, payload.ID)
    end
end)

SMS.LearnSpellForParty:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    local ability = payload.ability or "Wisdom"

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local learningStrategy = "AddChildren"
    local boostString = string.format("UnlockSpell(%s,%s,%s,,%s)", uuid, learningStrategy, "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", ability)

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        Osi.AddBoosts(charUUID, boostString, "", "")
        if not mods[charUUID] then mods[charUUID] = {} end
        if not mods[charUUID].spells then mods[charUUID].spells = {} end
        mods[charUUID].spells[uuid] = {
            spellName = uuid,
            learningStrategy = learningStrategy,
            castingAbility = ability,
            data = data
        }
    end

    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Spell" }, payload.ID)
end)

SMS.UnlearnSpellForParty:SetHandler(function(payload)
    local uuid = payload.uuid

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        if mods[charUUID] and mods[charUUID].spells and mods[charUUID].spells[uuid] then
            local spellData = mods[charUUID].spells[uuid]
            local boostString = string.format("UnlockSpell(%s,%s,%s,,%s)", spellData.spellName, spellData.learningStrategy, "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", spellData.castingAbility)
            Osi.RemoveBoosts(charUUID, boostString, 1, "", "")
            mods[charUUID].spells[uuid] = nil
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Spell" }, payload.ID)
end)

SMS.AddPassive:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    local character = payload.character

    if not character then return end
    
    if HLP.GetAttr(payload, "remove") then
        PASSV.Add(character, uuid, true)

        local passives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}
        if passives[character] then
            passives[character][uuid] = nil
        end
        
        Ext.Vars.GetModVariables(ModuleUUID).AddedPassives = passives
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
    else
        PASSV.Add(character, uuid)
   
        local passives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}
        if not passives[character] then passives[character] = {} end
        passives[character][uuid] = data
        
        Ext.Vars.GetModVariables(ModuleUUID).AddedPassives = passives
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
    end
end)

SMS.AddPassiveForParty:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local passives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        PASSV.Add(charUUID, uuid)
        if not passives[charUUID] then passives[charUUID] = {} end
        passives[charUUID][uuid] = data
    end

    Ext.Vars.GetModVariables(ModuleUUID).AddedPassives = passives
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
end)

SMS.RemovePassiveForParty:SetHandler(function(payload)
    local uuid = payload.uuid

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local passives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        PASSV.Add(charUUID, uuid, true) -- Remove the passive
        if passives[charUUID] then
            passives[charUUID][uuid] = nil
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).AddedPassives = passives
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
end)

SMS.AddPassiveOnItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local passiveUUID = payload.passiveUUID
    local data = payload.data
    
    -- Apply the passive to the item for the current session
    PASSV.AddOnItem(itemTemplateUUID, passiveUUID)

    -- Save the modification for persistence
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not modifiedEquipment[itemTemplateUUID] then
        modifiedEquipment[itemTemplateUUID] = {}
    end
    if not modifiedEquipment[itemTemplateUUID].passives then
        modifiedEquipment[itemTemplateUUID].passives = {}
    end
    modifiedEquipment[itemTemplateUUID].passives[passiveUUID] = data
    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
end)

SMS.RemovePassiveFromItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local passiveUUID = payload.passiveUUID

    -- Remove the passive from the item for the current session
    PASSV.RemoveFromItem(itemTemplateUUID, passiveUUID)

    -- Update saved modifications
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if modifiedEquipment[itemTemplateUUID] and modifiedEquipment[itemTemplateUUID].passives then
        modifiedEquipment[itemTemplateUUID].passives[passiveUUID] = nil
        if HLP.Count(modifiedEquipment[itemTemplateUUID].passives) == 0 then modifiedEquipment[itemTemplateUUID].passives = nil end
        if HLP.Count(modifiedEquipment[itemTemplateUUID]) == 0 then modifiedEquipment[itemTemplateUUID] = nil end
    end
    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Passive" }, payload.ID)
end)

SMS.ManageTag:SetHandler(function(payload)
    local tagId = payload.uuid
    local data = payload.data
    local character = payload.character

    if not character then return end

    if HLP.GetAttr(payload, "remove") then
        TAGS.Clear(character, tagId)

        local tags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}
        if tags[character] then
            tags[character][tagId] = nil
        end
        Ext.Vars.GetModVariables(ModuleUUID).AppliedTags = tags
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Tag" }, payload.ID)
    else
        TAGS.Set(character, tagId)
        local tags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}
        if not tags[character] then tags[character] = {} end
        tags[character][tagId] = data
        Ext.Vars.GetModVariables(ModuleUUID).AppliedTags = tags
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Tag" }, payload.ID)
    end
end)

SMS.AddTagForParty:SetHandler(function(payload)
    local tagId = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local tags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        TAGS.Set(charUUID, tagId)
        if not tags[charUUID] then tags[charUUID] = {} end
        tags[charUUID][tagId] = data
    end

    Ext.Vars.GetModVariables(ModuleUUID).AppliedTags = tags
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Tag" }, payload.ID)
end)

SMS.RemoveTagForParty:SetHandler(function(payload)
    local tagId = payload.uuid

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local tags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        TAGS.Clear(charUUID, tagId)
        if tags[charUUID] then
            tags[charUUID][tagId] = nil
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).AppliedTags = tags
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Tag" }, payload.ID)
end)

SMS.ApplyStatus:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    local character = payload.character

    if not character then return end
    
    if HLP.GetAttr(payload, "remove") then
        STAT.Apply(character, uuid, true)

        local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
        if statuses[character] then
            statuses[character][uuid] = nil
        end
        Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
    else
        STAT.Apply(character, uuid)

        local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
        if not statuses[character] then statuses[character] = {} end
        statuses[character][uuid] = data
        Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
    end
end)

SMS.ApplyStatusForParty:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        STAT.Apply(charUUID, uuid)
        if not statuses[charUUID] then statuses[charUUID] = {} end
        statuses[charUUID][uuid] = data
    end

    Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
end)

SMS.RemoveStatusForParty:SetHandler(function(payload)
    local uuid = payload.uuid

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        STAT.Apply(charUUID, uuid, true) -- Remove the status
        if statuses[charUUID] then
            statuses[charUUID][uuid] = nil
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
end)

SMS.ApplyStatusToItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local statusUUID = payload.statusUUID
    local data = payload.data
    
    -- Apply the status to the item for the current session
    STAT.ApplyToItem(itemTemplateUUID, statusUUID)

    -- Save the modification for persistence
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if not modifiedEquipment[itemTemplateUUID] then
        modifiedEquipment[itemTemplateUUID] = {}
    end
    if not modifiedEquipment[itemTemplateUUID].statuses then
        modifiedEquipment[itemTemplateUUID].statuses = {}
    end
    modifiedEquipment[itemTemplateUUID].statuses[statusUUID] = data
    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
end)

SMS.RemoveStatusFromItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local statusUUID = payload.statusUUID

    -- Remove the status from the item for the current session
    STAT.RemoveFromItem(itemTemplateUUID, statusUUID)

    -- Update saved modifications
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if modifiedEquipment[itemTemplateUUID] and modifiedEquipment[itemTemplateUUID].statuses then
        modifiedEquipment[itemTemplateUUID].statuses[statusUUID] = nil
        if HLP.Count(modifiedEquipment[itemTemplateUUID].statuses) == 0 then modifiedEquipment[itemTemplateUUID].statuses = nil end
        if HLP.Count(modifiedEquipment[itemTemplateUUID]) == 0 then modifiedEquipment[itemTemplateUUID] = nil end
    end
    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Status" }, payload.ID)
end)

SMS.SpawnTemplate:SetHandler(function(payload)
    local uuid = payload.uuid
    local amount = payload.amount
    local character = payload.character

    if not character then return end

    --print("Spawning " .. amount .. " " .. uuid)
    for i=1,amount do
        Osi.TemplateAddTo(uuid, character, 1, 0)
    end
end)

SMS.SpawnAllOfTemplateForParty:SetHandler(function(payload)
    local uuid = payload.uuid
    local amount = payload.amount or 1
    local partyMembers = HLP.GetAllChars()
    if not partyMembers or #partyMembers == 0 then return end

    for _, charUUID in ipairs(partyMembers) do
        for i=1,amount do
            Osi.TemplateAddTo(uuid, charUUID, 1, 0)
        end
    end
end)

SMS.SpawnAllEquipment:SetHandler(function(payload)
    local allItems = EKP.GetAllNonStoryItems()
    local character = payload.ID
    if not character then return end

    for _,uuid in ipairs(allItems) do
        Osi.TemplateAddTo(uuid, character, 1, 0)
    end
end)

SMS.SpawnCharacter:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    local amount = payload.amount

    for i=1,amount do
        local x,y,z = Osi.GetPosition(GetHostCharacter())
        local spawn = Osi.CreateAt(uuid, x, y, z, 1, 0, "")
        if spawn then
            Osi.SetCanJoinCombat(spawn, 0)

            local spawns = Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs or {}
            spawns[uuid] = data
            spawns[uuid]["created"] = spawn
            
            Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs = spawns
            HLP.ToClientDelayed(SMS.UIRefresh, { tab = "NPC" }, payload.ID)
        end
    end
end)
SMS.DespawnCharacter:SetHandler(function(payload)
    local uuid = payload.uuid
    local spawns = Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs or {}

    local spawn = HLP.GetAttr(spawns, uuid .. ".created")
    
    if HLP.GetEntity(spawn) then
        Osi.Die(spawn)
        Osi.TeleportToPosition(spawn, -999, -999, -999, "", 0, 0, 0, 0, 0)

        spawns[uuid] = nil
        
        Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs = spawns
        HLP.ToClientDelayed(SMS.UIRefresh, { tab = "NPC" }, payload.ID)
    end
end)
SMS.ManageNPC:SetHandler(function(payload)
    local uuid = payload.uuid
    local topic = payload.topic
    local can = payload.can
    local spawns = Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs or {}

    local spawn = HLP.GetAttr(spawns, uuid .. ".created")
    
    if HLP.GetEntity(spawn) then
        if topic == "combat" then
            Osi.SetCanJoinCombat(spawn, can)
        end
    end
end)

SMS.TeleportToWaypoint:SetHandler(function(payload)
    local trigger = payload.data

    --Osi.TeleportToPosition(GetHostCharacter(), pos.x, z, pos.y, "", 0, 0, 0, 0, 0)
    Osi.PROC_WaypointTeleportTo(GetHostCharacter(), trigger)
end)

SMS.RecruitCompanion:SetHandler(function(payload)
    local companion = payload.data 

    local char = HLP.Companions[HLP.Normalize(companion)]

    Osi.PROC_ORI_ClearPartnersIfAvatar(char);
    Osi.PROC_GLO_PartyMembers_Add(char, GetHostCharacter());
    Osi.TeleportTo(char,GetHostCharacter(),"", 0,0,0,0,0)
end)

-- Generic Cheats Handlers
SMS.AddGold:SetHandler(function(payload)
    local character = payload.ID
    local amount = payload.Amount
    if character and amount then
        Osi.AddGold(character, amount)
    end
end)

SMS.AddExperience:SetHandler(function(payload)
    local amount = payload.Amount
    if amount then
        Osi.AddExplorationExperience(GetHostCharacter(), amount)
    end
end)

SMS.AddTadpoles:SetHandler(function(payload)
    local character = payload.ID
    local amount = payload.Amount
    if character and amount then
        Osi.AddTadpole(character, amount)
    end
end)

SMS.AddInspiration:SetHandler(function(payload)
    local character = payload.ID
    local amount = payload.Amount
    if character and amount then
        Osi.GiveInspirationPoints(character, amount, "", "")
    end
end)

SMS.RestoreParty:SetHandler(function(payload)
    Osi.RestoreParty(GetHostCharacter())
end)

SMS.ResetCooldowns:SetHandler(function(payload)
    local character = payload.ID
    if character then
        Osi.ResetCooldowns(character)
    end
end)

SMS.StartRespec:SetHandler(function(payload)
    local character = payload.ID
    if character then
        Osi.StartRespec(character)
    end
end)

SMS.StartChangeAppearance:SetHandler(function(payload)
    local character = payload.ID
    if character then
        Osi.StartChangeAppearance(character)
    end
end)

SMS.CompanionApproval:SetHandler(function(payload)
    local companion = payload.data 
    local approval = payload.approval

    local char = HLP.Companions[HLP.Normalize(companion)]

    local currentApproval = Osi.GetApprovalRating(char, GetHostCharacter())
    --print(currentApproval)

    if approval == 100 then
        --print("Max approval")
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 1, 100)
    end
    if approval == -50 then
        --print("Min approval")
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 1, -150)
    end
    if approval == "+10" then
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 0, 10)
    end
    if approval == "-10" then
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 1, -10)
    end

end)

SMS.FetchPartyMembers:SetHandler(function(payload)
    local members = PARTY.GetMembers()
    HLP.ToClient(
        SMS.SendPartyMembers,
        { data = members },
        payload.ID
    )
end)

SMS.FetchModifiedItemsData:SetHandler(function(payload)
    local uuids = payload.uuids
    if not uuids then return end

    local itemsData = EKP.GetByUUIDs(uuids)

    HLP.ToClient(
        SMS.SendModifiedItemsData,
        { data = itemsData },
        payload.ID
    )
end)

SMS.FetchEquippedItems:SetHandler(function(payload)
    local partyMembers = PARTY.GetMembers()
    local itemsData = EKP.GetAllEquippedItems()

    HLP.ToClient(
        SMS.SendEquippedItems,
        { 
            party = partyMembers,
            items = itemsData 
        },
        payload.ID
    )
end)