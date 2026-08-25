--- Creates a generic handler for fetching paginated data from a module and sending it to the client.
---@param dataModule table The data module with a `GetAll(search, page)` function.
---@param sendMessage ExtNet.Channel The network channel to send the response on.
---@return function
local function CreateFetchHandler(dataModule, sendMessage)
    return function(payload)
        local search = HLP.GetAttr(payload, "search") or ""
        local page = HLP.GetAttr(payload, "page") or 1

        local items, totalItems, totalPages, currentPage = dataModule.GetAll(search, page, payload)

        HLP.ToClient(
            sendMessage,
            {
                tabInstanceId = payload.tabInstanceId,
                data = items,
                totalItems = totalItems,
                totalPages = totalPages,
                currentPage = currentPage
            },
            payload.ID
        )
    end
end

SMS.FetchEquipment:SetHandler(CreateFetchHandler(EKP, SMS.SendEquipment))
SMS.FetchNPCs:SetHandler(CreateFetchHandler(ENPC, SMS.SendNPCs))
SMS.FetchSpells:SetHandler(CreateFetchHandler(SPLL, SMS.SendSpells))
SMS.FetchResources:SetHandler(CreateFetchHandler(RSRC, SMS.SendResources))
SMS.FetchWaypoints:SetHandler(CreateFetchHandler(TELP, SMS.SendWaypoints))
SMS.FetchConsumables:SetHandler(CreateFetchHandler(CONS, SMS.SendConsumables))
SMS.FetchPassives:SetHandler(CreateFetchHandler(PASSV, SMS.SendPassives))
SMS.FetchStatuses:SetHandler(CreateFetchHandler(STAT, SMS.SendStatuses))
SMS.FetchOtherItems:SetHandler(CreateFetchHandler(OITM, SMS.SendOtherItems))
SMS.FetchTags:SetHandler(CreateFetchHandler(TAGS, SMS.SendTags))
SMS.FetchReactions:SetHandler(CreateFetchHandler(REACT, SMS.SendReactions))

-- Spells
SMS.LearnSpell:SetHandler(function(payload) SPLL.Manage(payload) end)
SMS.LearnSpellForParty:SetHandler(function(payload) SPLL.ManageForParty(payload) end)
SMS.UnlearnSpellForParty:SetHandler(function(payload) SPLL.ManageForParty(payload, true) end)

-- Resources
SMS.ManageResource:SetHandler(function(payload) RSRC.Manage(payload) end)
SMS.AddResourceForParty:SetHandler(function(payload) RSRC.ManageForParty(payload) end)
SMS.RemoveResourceForParty:SetHandler(function(payload) RSRC.ManageForParty(payload, true) end)

-- Abilities
SMS.FetchAbilities:SetHandler(function(payload) ABIL.Fetch(payload) end)

SMS.ClearAllAbilityBoosts:SetHandler(function(payload) ABIL.ClearAllBoosts(payload) end)
SMS.ManageAbility:SetHandler(function(payload) ABIL.Manage(payload) end)
-- Skills
SMS.ManageSkill:SetHandler(function(payload) SKL.Manage(payload) end)
SMS.ClearAllSkillBoosts:SetHandler(function(payload) SKL.ClearAllBoosts(payload) end)

-- Proficiencies
SMS.ManageProficiency:SetHandler(function(payload) PROF.Manage(payload) end)
SMS.ClearAllProficiencyBoosts:SetHandler(function(payload) PROF.ClearAllBoosts(payload) end)

-- Resistances
SMS.ManageResistance:SetHandler(function(payload) RES.Manage(payload) end)
SMS.ClearAllResistanceBoosts:SetHandler(function(payload) RES.ClearAllBoosts(payload) end)

-- Reactions
SMS.ManageReaction:SetHandler(function(payload) REACT.Manage(payload) end)
SMS.ClearAllReactionBoosts:SetHandler(function(payload) REACT.ClearAllBoosts(payload) end)

-- Character Buffs
SMS.ManageCharacterBuff:SetHandler(function(payload) CBF.Manage(payload) end)
SMS.ClearAllCharacterBuffs:SetHandler(function(payload) CBF.ClearAllBoosts(payload) end)

-- Passives
SMS.AddPassive:SetHandler(function(payload) PASSV.Manage(payload) end)
SMS.AddPassiveForParty:SetHandler(function(payload) PASSV.ManageForParty(payload) end)
SMS.RemovePassiveForParty:SetHandler(function(payload) PASSV.ManageForParty(payload, true) end)
SMS.AddPassiveOnItem:SetHandler(function(payload) PASSV.ManageOnItem(payload) end)
SMS.RemovePassiveFromItem:SetHandler(function(payload) PASSV.ManageOnItem(payload, true) end)
SMS.AddDirectPassiveToItem:SetHandler(function(payload) PASSV.ManageDirectOnItem(payload) end)
SMS.RemoveDirectPassiveFromItem:SetHandler(function(payload) PASSV.ManageDirectOnItem(payload, true) end)

-- Tags
SMS.ManageTag:SetHandler(function(payload) TAGS.Manage(payload) end)
SMS.AddTagForParty:SetHandler(function(payload) TAGS.ManageForParty(payload) end)
SMS.RemoveTagForParty:SetHandler(function(payload) TAGS.ManageForParty(payload, true) end)

-- Statuses
SMS.ApplyStatus:SetHandler(function(payload) STAT.Manage(payload) end)
SMS.ApplyStatusForParty:SetHandler(function(payload) STAT.ManageForParty(payload) end)
SMS.RemoveStatusForParty:SetHandler(function(payload) STAT.ManageForParty(payload, true) end)
SMS.ApplyStatusToItem:SetHandler(function(payload) STAT.ManageOnItem(payload) end)
SMS.RemoveStatusFromItem:SetHandler(function(payload) STAT.ManageOnItem(payload, true) end)
SMS.AddDirectStatusToItem:SetHandler(function(payload) STAT.ManageDirectOnItem(payload) end)
SMS.RemoveDirectStatusFromItem:SetHandler(function(payload) STAT.ManageDirectOnItem(payload, true) end)

-- Damage
SMS.ManageDamageOnItem:SetHandler(function(payload) DMG.ManageOnItem(payload, payload.remove) end)

-- Spawning
SMS.SpawnTemplate:SetHandler(function(payload) EKP.Spawn(payload) end)
SMS.SpawnAllOfTemplateForParty:SetHandler(function(payload) EKP.SpawnForParty(payload) end)
SMS.SpawnAllEquipment:SetHandler(function(payload) EKP.SpawnAll(payload) end)
SMS.SpawnFilteredEquipment:SetHandler(function(payload) EKP.SpawnFiltered(payload) end)
SMS.SpawnCharacter:SetHandler(function(payload) ENPC.Spawn(payload) end)
SMS.DespawnCharacter:SetHandler(function(payload) ENPC.Despawn(payload) end)
SMS.ManageNPC:SetHandler(function(payload) ENPC.Manage(payload) end)

-- Teleportation
SMS.TeleportToWaypoint:SetHandler(function(payload) TELP.Teleport(payload) end)

-- Party & Companions
SMS.RecruitCompanion:SetHandler(function(payload) PARTY.Recruit(payload) end)
SMS.CompanionApproval:SetHandler(function(payload) PARTY.SetApproval(payload) end)
SMS.FetchPartyMembers:SetHandler(function(payload)
    local members = PARTY.GetMembers()
    HLP.ToClient(
        SMS.SendPartyMembers,
        { data = members },
        payload.ID
    )
end)

-- Generic Cheats
SMS.AddGold:SetHandler(function(payload) GEN.AddGold(payload) end)
SMS.AddExperience:SetHandler(function(payload) GEN.AddExperience(payload) end)
SMS.AddTadpoles:SetHandler(function(payload) GEN.AddTadpoles(payload) end)
SMS.AddInspiration:SetHandler(function(payload) GEN.AddInspiration(payload) end)
SMS.RestoreParty:SetHandler(function(payload) GEN.RestoreParty(payload) end)
SMS.ResetCooldowns:SetHandler(function(payload) GEN.ResetCooldowns(payload) end)
SMS.StartRespec:SetHandler(function(payload) GEN.StartRespec(payload) end)
SMS.StartChangeAppearance:SetHandler(function(payload) GEN.StartChangeAppearance(payload) end)

-- Item/Equipment Data
SMS.FetchModifiedItemsData:SetHandler(function(payload)
    local uuids = payload.uuids
    if not uuids then return end

    local itemsData = EKP.GetByUUIDs(uuids)

    HLP.ToClient(
        SMS.SendModifiedItemsData,
        { data = itemsData },
        payload.ID
    )
end)

SMS.FetchEquippedItems:SetHandler(function(payload)
    local partyMembers = PARTY.GetMembers()
    local itemsData = EKP.GetAllEquippedItems()

    HLP.ToClient(
        SMS.SendEquippedItems,
        { 
            party = partyMembers,
            items = itemsData 
        },
        payload.ID
    )
end)

SMS.FetchEquipmentModNames:SetHandler(function(payload)
    local itemData = Ext.Template.GetAllRootTemplates()
    local extractor = function(template)
        local data = EKP.GetTemplateData(template)
        return data and data.modName
    end
    local modNames = FLTR.GetModNames(itemData, extractor)
    HLP.ToClient(
        SMS.SendEquipmentModNames,
        { data = modNames },
        payload.ID
    )
end)

SMS.FetchConsumableModNames:SetHandler(function(payload)
    local itemData = Ext.Template.GetAllRootTemplates()
    local extractor = function(template)
        if CONS.IsConsumable(template) then
            local stats = Ext.Stats.Get(template.Stats)
            if stats then
                local modId = HLP.GetAttr(stats, "ModId")
                local mod = Ext.Mod.GetMod(modId)
                return mod and mod.Info and mod.Info.Name or "Unknown"
            end
        end
        return nil
    end
    local modNames = FLTR.GetModNames(itemData, extractor)
    HLP.ToClient(
        SMS.SendConsumableModNames,
        { data = modNames },
        payload.ID
    )
end)

SMS.FetchOtherItemModNames:SetHandler(function(payload)
    local itemData = Ext.Template.GetAllRootTemplates()
    local extractor = function(template)
        if HLP.GetAttr(template, "TemplateType") == "item" and not EKP.IsEquipable(template) and not CONS.IsConsumable(template) then
            local stats = Ext.Stats.Get(template.Stats)
            if stats then
                local modId = HLP.GetAttr(stats, "ModId")
                local mod = Ext.Mod.GetMod(modId)
                return mod and mod.Info and mod.Info.Name or "Unknown"
            end
        end
        return nil
    end
    local modNames = FLTR.GetModNames(itemData, extractor)
    HLP.ToClient(SMS.SendOtherItemModNames, { data = modNames }, payload.ID)
end)

local function CreateStatsModNameFetchHandler(statsType, sendMessage)
    return function(payload)
        local itemData = Ext.Stats.GetStats(statsType)
        local extractor = function(statName)
            local v = Ext.Stats.Get(statName)
            if not v then return nil end
            local modId = HLP.GetAttr(v, "ModId")
            local mod = Ext.Mod.GetMod(modId)
            return mod and mod.Info and mod.Info.Name or "Unknown"
        end
        local modNames = FLTR.GetModNames(itemData, extractor)
        HLP.ToClient(sendMessage, { data = modNames }, payload.ID)
    end
end

SMS.FetchSpellModNames:SetHandler(CreateStatsModNameFetchHandler("SpellData", SMS.SendSpellModNames))
SMS.FetchPassiveModNames:SetHandler(CreateStatsModNameFetchHandler("PassiveData", SMS.SendPassiveModNames))
SMS.FetchStatusModNames:SetHandler(CreateStatsModNameFetchHandler("StatusData", SMS.SendStatusModNames))
SMS.FetchReactionModNames:SetHandler(CreateStatsModNameFetchHandler("InterruptData", SMS.SendReactionModNames))