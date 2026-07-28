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

SMS.LearnSpell:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data

    local allChars = HLP.GetAllChars()
    
    if HLP.GetAttr(payload, "unlearn") then
        for _,char in pairs(allChars) do
            if Osi.IsPlayer(char) == 1 then
                Osi.RemoveSpell(char, uuid, 1)
            end
        end

        local spells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}
        spells[uuid] = nil
        
        Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells = spells
    else
        for _,char in pairs(allChars) do
            if Osi.IsPlayer(char) == 1 then
                Osi.AddSpell(char, uuid, 1, 1)
            end
        end

        local spells = Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells or {}
        spells[uuid] = data
        
        Ext.Vars.GetModVariables(ModuleUUID).LearnedSpells = spells
    end
end)

SMS.LearnPassive:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    
    if HLP.GetAttr(payload, "unlearn") then
        PASSV.Learn(uuid, true)

        local passives = Ext.Vars.GetModVariables(ModuleUUID).LearnedPassives or {}
        passives[uuid] = nil
        
        Ext.Vars.GetModVariables(ModuleUUID).LearnedPassives = passives
    else
        PASSV.Learn(uuid)
   
        local passives = Ext.Vars.GetModVariables(ModuleUUID).LearnedPassives or {}
        passives[uuid] = data
        
        Ext.Vars.GetModVariables(ModuleUUID).LearnedPassives = passives
    end
end)

SMS.ApplyStatus:SetHandler(function(payload)
    local uuid = payload.uuid
    local data = payload.data
    
    if HLP.GetAttr(payload, "remove") then
        STAT.Apply(Osi.GetHostCharacter(), uuid, true)

        local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
        statuses[uuid] = nil
        Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
    else
        STAT.Apply(Osi.GetHostCharacter(), uuid)

        local statuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
        statuses[uuid] = data
        Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses = statuses
    end
end)


SMS.SpawnTemplate:SetHandler(function(payload)
    local uuid = payload.uuid
    local amount = payload.amount

    --print("Spawning " .. amount .. " " .. uuid)
    for i=1,amount do
        Osi.TemplateAddTo(uuid, GetHostCharacter(), 1, 0)
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