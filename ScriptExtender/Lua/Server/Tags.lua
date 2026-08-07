TAGS = {}
TAGS.Max = 50

function TAGS.GetAll(search, page)
    search = search or ""
    page = page or 1
    local pageSize = TAGS.Max

    local tagData = Ext.StaticData.GetAll("Tag")
    local allMatchingTags = {}

    for _, tagId in pairs(tagData) do
        local staticData = Ext.StaticData.Get(tagId, "Tag")
        local displayName = HLP.GetTranslatedString(staticData.DisplayName.Handle.Handle, staticData.Name)
        local displayDescription = Ext.Loca.GetTranslatedString(staticData.DisplayDescription.Handle.Handle, staticData.Description)

        local matchesSearch = (search == "") or (displayName and HLP.StrContains(search, displayName))

        if matchesSearch and displayName and displayName ~= "" then
            table.insert(allMatchingTags, {
                id = tagId,
                displayName = displayName,
                displayDescription = displayDescription
            })
        end
    end

    table.sort(allMatchingTags, function(a, b) return a.displayName < b.displayName end)

    return UTL.Paginate(allMatchingTags, page, pageSize)
end

function TAGS.Set(character, tagId)
    Osi.SetTag(character, tagId)
end

function TAGS.Clear(character, tagId)
    Osi.ClearTag(character, tagId)
end

function TAGS.Manage(payload)
    local tagId = payload.uuid
    local data = payload.data
    local character = payload.character
    local remove = HLP.GetAttr(payload, "remove")

    if not character then return end

    local tags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}
    if not tags[character] then tags[character] = {} end

    if remove then
        TAGS.Clear(character, tagId)
        tags[character][tagId] = nil
    else
        TAGS.Set(character, tagId)
        tags[character][tagId] = data
    end
    
    Ext.Vars.GetModVariables(ModuleUUID).AppliedTags = tags
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Tag" }, payload.ID)
end

function TAGS.ManageForParty(payload, remove)
    local tagId = payload.uuid
    local data = payload.data

    local partyMembers = PARTY.GetMembers()
    if not partyMembers or #partyMembers == 0 then return end

    local tags = Ext.Vars.GetModVariables(ModuleUUID).AppliedTags or {}

    for _, member in ipairs(partyMembers) do
        local charUUID = member.uuid
        if not tags[charUUID] then tags[charUUID] = {} end
        
        if remove then
            TAGS.Clear(charUUID, tagId)
            tags[charUUID][tagId] = nil
        else
            TAGS.Set(charUUID, tagId)
            tags[charUUID][tagId] = data
        end
    end

    Ext.Vars.GetModVariables(ModuleUUID).AppliedTags = tags
    HLP.ToClientDelayed(SMS.UIRefresh, { tab = "Tag" }, payload.ID)
end