local serverOnly = {
    Server = true,
}
local serverAndClient = {
    Server = true, Client = true, SyncToClient = true
}

Ext.Vars.RegisterModVariable(ModuleUUID, "AllEquipment", serverAndClient) 
Ext.Vars.RegisterModVariable(ModuleUUID, "SpawnedNPCs", serverAndClient)
Ext.Vars.RegisterModVariable(ModuleUUID, "AllConsumables", serverAndClient)
Ext.Vars.RegisterModVariable(ModuleUUID, "LearnedSpells", serverAndClient)