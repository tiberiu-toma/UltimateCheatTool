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

function PARTY.Recruit(payload)
    local companion = payload.data 
    local char = HLP.Companions[HLP.Normalize(companion)]
    if not char then return end

    Osi.PROC_ORI_ClearPartnersIfAvatar(char);
    Osi.PROC_GLO_PartyMembers_Add(char, GetHostCharacter());
    Osi.TeleportTo(char,GetHostCharacter(),"", 0,0,0,0,0)
end

function PARTY.SetApproval(payload)
    local companion = payload.data 
    local approval = payload.approval
    local char = HLP.Companions[HLP.Normalize(companion)]
    if not char then return end

    if approval == 100 then
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 1, 100)
    elseif approval == -50 then
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 1, -150)
    elseif approval == "+10" then
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 0, 10)
    elseif approval == "-10" then
        Osi.ChangeApprovalRating(char, GetHostCharacter(), 1, -10)
    end
end