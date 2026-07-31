SMS.FetchEquipment:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""
    local page = HLP.GetAttr(payload, "page") or 1

    local equipment, totalItems, totalPages, currentPage = EKP.GetAll(search, page)

    HLP.ToClient(
        SMS.SendEquipment,
        {
            data = equipment,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage
        },
        payload.ID
    )
end)

SMS.FetchNPCs:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""
    local page = HLP.GetAttr(payload, "page") or 1

    local NPCs, totalItems, totalPages, currentPage = ENPC.GetAll(search, page)

    HLP.ToClient(
        SMS.SendNPCs,
        {
            data = NPCs,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage
        },
        payload.ID
    )
end)

SMS.FetchSpells:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""
    local page = HLP.GetAttr(payload, "page") or 1

    local spells, totalItems, totalPages, currentPage = SPLL.GetAll(search, page)

    HLP.ToClient(
        SMS.SendSpells,
        {
            data = spells,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage
        },
        payload.ID
    )
end)

SMS.FetchWaypoints:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""

    local Waypoints = TELP.GetAll(search)

    HLP.ToClient(
        SMS.SendWaypoints,
        {
            data = Waypoints
        },
        payload.ID
    )
end)

SMS.FetchConsumables:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""
    local page = HLP.GetAttr(payload, "page") or 1

    local Consumables, totalItems, totalPages, currentPage = CONS.GetAll(search, page)

    HLP.ToClient(
        SMS.SendConsumables,
        {
            data = Consumables,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage
        },
        payload.ID
    )
end)

SMS.FetchPassives:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""
    local page = HLP.GetAttr(payload, "page") or 1
 
    local passives, totalItems, totalPages, currentPage = PASSV.GetAll(search, page)

    HLP.ToClient(
        SMS.SendPassives,
        {
            data = passives,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage
        },
        payload.ID
    )
end)

SMS.FetchStatuses:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""
    local page = HLP.GetAttr(payload, "page") or 1

    local statuses, totalItems, totalPages, currentPage = STAT.GetAll(search, page)

    HLP.ToClient(
        SMS.SendStatuses,
        {
            data = statuses,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage
        },
        payload.ID
    )
end)

SMS.FetchTags:SetHandler(function(payload)
    local search = HLP.GetAttr(payload, "search") or ""
    local page = HLP.GetAttr(payload, "page") or 1

    local tags, totalItems, totalPages, currentPage = TAGS.GetAll(search, page)

    HLP.ToClient(
        SMS.SendTags,
        {
            data = tags,
            totalItems = totalItems,
            totalPages = totalPages,
            currentPage = currentPage
        },
        payload.ID
    )
end)

SMS.LearnSpell:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    local character = payload.character

    if not character then return end
    
    if HLP.GetAttr(payload, "unlearn") then
        SPLL.Learn(character, uuid, true)

        local spells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}
        if spells[character] then
            spells[character][uuid] = nil
        end
        
        Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells = spells
    else
        SPLL.Learn(character, uuid)

        local spells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}
        if not spells[character] then spells[character] = {} end
        spells[character][uuid] = data
        
        Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells = spells
    end
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
    else
        PASSV.Add(character, uuid)
   
        local passives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}
        if not passives[character] then passives[character] = {} end
        passives[character][uuid] = data
        
        Ext.Vars.GetModVariables(ModuleUUID).AddedPassives = passives
    end
end)

SMS.AddPassiveOnItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local passiveUUID = payload.passiveUUID
    local data = payload.data
    local character = payload.character

    if not character then return end
    
    -- Apply the passive to the item for the current session
    PASSV.AddOnItem(character, itemTemplateUUID, passiveUUID)

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
end)

SMS.RemovePassiveFromItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local passiveUUID = payload.passiveUUID
    local character = payload.character

    if not character then return end

    -- Remove the passive from the item for the current session
    PASSV.RemoveFromItem(character, itemTemplateUUID, passiveUUID)

    -- Update saved modifications
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if modifiedEquipment[itemTemplateUUID] and modifiedEquipment[itemTemplateUUID].passives then
        modifiedEquipment[itemTemplateUUID].passives[passiveUUID] = nil
        if HLP.Count(modifiedEquipment[itemTemplateUUID].passives) == 0 then modifiedEquipment[itemTemplateUUID].passives = nil end
        if HLP.Count(modifiedEquipment[itemTemplateUUID]) == 0 then modifiedEquipment[itemTemplateUUID] = nil end
    end
    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
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
    else
        TAGS.Set(character, tagId)
        local tags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}
        if not tags[character] then tags[character] = {} end
        tags[character][tagId] = data
        Ext.Vars.GetModVariables(ModuleUUID).AppliedTags = tags
    end
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
    else
        STAT.Apply(character, uuid)

        local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
        if not statuses[character] then statuses[character] = {} end
        statuses[character][uuid] = data
        Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
    end
end)

SMS.ApplyStatusToItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local statusUUID = payload.statusUUID
    local data = payload.data
    local character = payload.character

    if not character then return end
    
    -- Apply the status to the item for the current session
    STAT.ApplyToItem(character, itemTemplateUUID, statusUUID)

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
end)

SMS.RemoveStatusFromItem:SetHandler(function(payload)
    local itemTemplateUUID = payload.itemTemplateUUID
    local statusUUID = payload.statusUUID
    local character = payload.character

    if not character then return end

    -- Remove the status from the item for the current session
    STAT.RemoveFromItem(character, itemTemplateUUID, statusUUID)

    -- Update saved modifications
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    if modifiedEquipment[itemTemplateUUID] and modifiedEquipment[itemTemplateUUID].statuses then
        modifiedEquipment[itemTemplateUUID].statuses[statusUUID] = nil
        if HLP.Count(modifiedEquipment[itemTemplateUUID].statuses) == 0 then modifiedEquipment[itemTemplateUUID].statuses = nil end
        if HLP.Count(modifiedEquipment[itemTemplateUUID]) == 0 then modifiedEquipment[itemTemplateUUID] = nil end
    end
    Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment = modifiedEquipment
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
    local characterUUID = payload.character
    if not characterUUID then return end

    local itemsData = EKP.GetEquippedItems(characterUUID)

    HLP.ToClient(
        SMS.SendEquippedItems,
        { data = itemsData },
        payload.ID
    )
end)