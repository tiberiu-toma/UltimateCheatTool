VIS = {}

function VIS.RemoveSlots(char)
    local entity = HLP.GetEntity(char)
    local data = {}

    for slotType,_ in pairs(NKD.NPCSlotsToRemove) do
        if entity and HLP.GetAttr(entity, "ServerCharacter") then

            local vrID = HLP.GetAttr(entity, "ServerCharacter.Template.CharacterVisualResourceID")
            local slots = HLP.GetAttr(Ext.Resource.Get(vrID, "CharacterVisual"), "VisualSet.Slots")

            for i, entry in pairs(slots) do
                if  entry.Slot == slotType then
                    table.insert(data, {uuid = entry.VisualResource, index = i})
                    entry.VisualResource = ""
                end
            end

        end
    end

    return data
end

function VIS.RestoreSlots(char, charSlots)
    local entity = HLP.GetEntity(char)

    for slotType,_ in pairs(NKD.NPCSlotsToRemove) do

        local vrID = HLP.GetAttr(entity, "ServerCharacter.Template.CharacterVisualResourceID")
        local slots = HLP.GetAttr(Ext.Resource.Get(vrID, "CharacterVisual"), "VisualSet.Slots")

        for i, entry in pairs(slots) do
            for _,slot in ipairs(charSlots) do
                local uuid = slot.uuid
                local index = slot.index
                if index == i and string.len(uuid) > 1 then
                    ----print("Restoring slot " .. uuid .. "for " .. char)
                    entry.VisualResource = uuid
                end
            end
        end
    end
end

function VIS.Refresh(char)
    local char = HLP.GetChar(char)
    local entity = HLP.GetEntity(char)

    if HLP.IsNPC(char) == true then
        entity:Replicate("GameObjectVisual")
    end
    entity:Replicate("CharacterCreationAppearance")
end