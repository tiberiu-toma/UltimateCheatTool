ENPC = {}
ENPC.Max = 50

function ENPC.GetAll(search, page, filters)
    search = search or ""
    page = page or 1
    local pageSize = ENPC.Max

    local itemData = Ext.Template.GetAllRootTemplates()

    local allMatchingNPCs = {}

    for k,v in pairs(itemData) do 
        if HLP.GetAttr(v, "TemplateType") == "character" then
            local id = HLP.GetAttr(v, "Id")
            local icon = HLP.GetAttr(v, "Icon")
            local name = HLP.GetAttr(v, "Name")
            local handle = HLP.GetAttr(v, "DisplayName.Handle.Handle")
            local displayName = HLP.GetTranslatedString(handle, name)

            local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

            if matchesSearch and displayName and displayName ~= "" then
                local isNPC = true
                if isNPC then
                    table.insert(allMatchingNPCs, {
                        id = id,
                        name = name,
                        icon = icon,
                        displayName = displayName
                    })
                end
            end
        end
    end

    table.sort(allMatchingNPCs, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingNPCs, page, pageSize)
end

function ENPC.Spawn(payload)
    local uuid = payload.uuid
    local data = payload.data
    local amount = payload.amount or 1

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
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "NPC" }, payload.ID)
end

function ENPC.Despawn(payload)
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
end

function ENPC.Manage(payload)
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
end