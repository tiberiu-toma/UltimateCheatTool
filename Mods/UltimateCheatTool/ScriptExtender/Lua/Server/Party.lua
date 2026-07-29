PARTY = {}

---@return table
function PARTY.GetMembers()
    local members = Ext.Entity.GetAllEntitiesWithComponent("PartyMember")
    local partyData = {}
    for _, entity in ipairs(members) do
        local charGuid = entity.Uuid.EntityUuid
        if charGuid and entity.DisplayName and entity.DisplayName.Name and entity.DisplayName.Name.Handle then
            local name = Ext.Loca.GetTranslatedString(entity.DisplayName.Name.Handle.Handle)
            table.insert(partyData, {
                uuid = charGuid,
                name = name,
            })
        end
    end
    return partyData
end