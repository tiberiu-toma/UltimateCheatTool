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

    local originalSlot = HLP.GetAttr(stats, "Slot")
    if not originalSlot then return end

    local slotsToCheck = { originalSlot }
    if originalSlot == "Melee Main Weapon" then
        table.insert(slotsToCheck, "Melee Offhand Weapon")
    elseif originalSlot == "Ranged Main Weapon" then
        table.insert(slotsToCheck, "Ranged Offhand Weapon")
    elseif originalSlot == "Ring" then
        table.insert(slotsToCheck, "Ring2")
    end

    for _, slot in ipairs(slotsToCheck) do
        local itemHandle = Osi.GetEquippedItem(character, slot)
        if itemHandle ~= 0 then
            local item = Ext.Entity.Get(itemHandle)
            if item and item.GameObjectVisual and item.GameObjectVisual.RootTemplateId == itemTemplateUUID then
                Osi.Unequip(character, itemHandle)
                local ticks = 0
                local e
                e = Ext.Events.Tick:Subscribe(function()
                    ticks = ticks + 1
                    if ticks >= 10 then
                        Osi.Equip(character, itemHandle)
                        Ext.Events.Tick:Unsubscribe(e)
                    end
                end)                
            end
        end
    end
end