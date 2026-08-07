RSRC = {}
RSRC.Max = 50

function RSRC.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = RSRC.Max

    local resourceData = Ext.StaticData.GetAll("ActionResource")
    local allMatchingResources = {}

    for _, resourceUUID in ipairs(resourceData) do
        local staticData = Ext.StaticData.Get(resourceUUID, "ActionResource")
        if staticData then
            local name = staticData.Name
            local displayName = HLP.GetTranslatedString(staticData.DisplayName.Handle.Handle, name)
            local description = Ext.Loca.GetTranslatedString(staticData.Description.Handle.Handle)
            local maxLevel = staticData.MaxLevel or 0 -- Get MaxLevel, default to 0

            local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName)) or (name and HLP.StrContains(search, name))

            if matchesSearch and displayName and displayName ~= "" then
                table.insert(allMatchingResources, {
                    id = name,
                    uuid = resourceUUID,
                    name = name,
                    displayName = displayName,
                    description = description,
                    maxLevel = maxLevel
                })
            end
        end
    end

    table.sort(allMatchingResources, function(a, b) return a.displayName < b.displayName end)
    return UTL.Paginate(allMatchingResources, page, pageSize)
end

function RSRC._Manage(character, resourceId, data, amount, level, remove, uniqueKey)
    if not character then return end

    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    if not mods[character] then mods[character] = {} end
    if not mods[character].resources then mods[character].resources = {} end

    if remove then
        local resourceData = mods[character].resources[uniqueKey]
        if resourceData and resourceData.boostString then
            Osi.RemoveBoosts(character, resourceData.boostString, 1, "", "")
            mods[character].resources[uniqueKey] = nil
        end
    else
        local boostString = string.format("ActionResource(%s,%s,%s)", resourceId, amount, level)
        Osi.AddBoosts(character, boostString, "", "")

        local newUniqueKey = boostString .. ":" .. tostring(Ext.Timer.MonotonicTime()) .. ":" .. tostring(math.random(1, 1000000))
        mods[character].resources[newUniqueKey] = { id = resourceId, name = data.name, displayName = data.displayName, description = data.description, amount = amount, level = level, maxLevel = data.maxLevel, boostString = boostString }
    end

    Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications = mods
end

function RSRC.Manage(payload)
    RSRC._Manage(payload.character, payload.uuid, payload.data, payload.amount or 1, payload.level or 0, HLP.GetAttr(payload, "remove"), payload.uuid)
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Resource" }, payload.ID)
end

function RSRC.ManageForParty(payload, remove)
    local resourceId = payload.uuid
    local data = payload.data
    local amount = payload.amount or 1
    local level = payload.level or 0

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end
    
    local mods = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}

    if remove then
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
    else
        for _, member in ipairs(partyMembers) do
            RSRC._Manage(member.uuid, resourceId, data, amount, level, false)
        end
    end

    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Resource" }, payload.ID)
end