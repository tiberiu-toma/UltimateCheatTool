SMS.SendEquipment:SetHandler(function (payload)
    if UI then
        local equipment = payload.data
        
        local tab = UI.EquipmentTab

        tab:SetEquipment(equipment)
    end
end)
SMS.SendNPCs:SetHandler(function (payload)
    if UI then
        local NPCs = payload.data
        
        local tab = UI.NPCTab

        tab:SetNPCs(NPCs)
    end
end)
SMS.SendSpells:SetHandler(function (payload)
    if UI then
        local Spells = payload.data
        
        local tab = UI.SpellTab

        tab:SetSpells(Spells)
    end
end)
SMS.SendPassives:SetHandler(function (payload)
    if UI then
        local Passives = payload.data
        
        local tab = UI.PassiveTab

        tab:SetPassives(Passives)
    end
end)
SMS.SendStatuses:SetHandler(function (payload)
    if UI then
        local Statuses = payload.data
        
        local tab = UI.StatusTab

        tab:SetStatuses(Statuses)
    end
end)
SMS.SendConsumables:SetHandler(function (payload)
    if UI then
        local Consumables = payload.data
        
        local tab = UI.ConsumableTab

        tab:SetConsumables(Consumables)
    end
end)
SMS.SendWaypoints:SetHandler(function (payload)
    if UI then
        local Waypoints = payload.data
        
        local tab = UI.WaypointTab

        tab:SetWaypoints(Waypoints)
    end
end)