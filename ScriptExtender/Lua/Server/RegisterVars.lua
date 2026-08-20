local serverOnly = {
    Server = true,
}
local serverAndClient = {
    Server = true, Client = true, SyncToClient = true
}

Ext.Vars.RegisterModVariable(ModuleUUID, "SpawnedNPCs", serverAndClient) 
Ext.Vars.RegisterModVariable(ModuleUUID, "CharacterModifications", serverAndClient)
Ext.Vars.RegisterModVariable(ModuleUUID, "AddedPassives", serverAndClient)
Ext.Vars.RegisterModVariable(ModuleUUID, "AppliedStatuses", serverAndClient)
Ext.Vars.RegisterModVariable(ModuleUUID, "AppliedTags", serverAndClient)
Ext.Vars.RegisterModVariable(ModuleUUID, "ModifiedEquipment", serverAndClient)
Ext.Vars.RegisterModVariable(ModuleUUID, "ResourceAmountSnapshots", serverAndClient)