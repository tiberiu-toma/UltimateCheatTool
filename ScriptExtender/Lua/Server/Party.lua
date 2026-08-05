PARTY = {}

---@return table
function PARTY.GetMembers()
    local members = Ext.Entity.GetAllEntitiesWithComponent("PartyMember")
    local partyData = {}

    local companionUUIDs = {}
    for name, uuid in pairs(HLP.Companions) do
        companionUUIDs[uuid] = name
    end

    for _, entity in ipairs(members) do
        local charGuid = entity.Uuid.EntityUuid
        if charGuid and entity.DisplayName and entity.DisplayName.Name and entity.DisplayName.Name.Handle then
            local name = Ext.Loca.GetTranslatedString(entity.DisplayName.Name.Handle.Handle)
            local icon = "EC_Portrait_Generic"

            local companionName = companionUUIDs[charGuid]
            if companionName then
                local portraitName = HLP.Ucfirst(companionName)
                if portraitName == "Shadowheart" then portraitName = "ShadowHeart" end
                icon = "EC_Portrait_" .. portraitName
            end

            table.insert(partyData, {
                uuid = charGuid,
                name = name,
                icon = icon,
            })
        end
    end
    return partyData
end