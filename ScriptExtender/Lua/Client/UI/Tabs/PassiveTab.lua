local ModifiableStatTab = Ext.Require("Client/UI/Tabs/ModifiableStatTab.lua")

---@class PassiveTab : ModifiableStatTab
PassiveTab = {}
setmetatable(PassiveTab, { __index = ModifiableStatTab })
PassiveTab.__index = PassiveTab

function PassiveTab:New(holder, parentUI)
    local config = {
        tabName = "Passives",
        tabNameHandle = "UCT_PassiveTab_Label",
        idPrefix = "Passive",
        fetchMessage = SMS.FetchPassives,
        searchLabel = "Search Passives:",
        searchLabelHandle = "UCT_SearchPassives_Label",
        noItemsText = "No passives found.",
        maxTableWidth = 5,
        filters = { mod = true },

        -- ModifiableStatTab config
        statName = "Passive",
        statNamePlural = "Passives",
        statNameLowerPlural = "passives",
        statUUIDKey = "passiveUUID",
        addBtnLabel = "UCT_PassiveTab_Add",
        removeBtnLabel = "UCT_PassiveTab_Remove",
        
        sms = {
            fetchModNames = SMS.FetchPassiveModNames,
            add = SMS.AddPassive,
            remove = SMS.AddPassive,
            addForParty = SMS.AddPassiveForParty,
            removeForParty = SMS.RemovePassiveForParty,
            addOnItemEquip = SMS.AddPassiveOnItem,
            removeFromItemEquip = SMS.RemovePassiveFromItem,
            addOnItemDirect = SMS.AddDirectPassiveToItem,
            removeFromItemDirect = SMS.RemoveDirectPassiveFromItem
        },
        
        vars = {
            charKey = "AddedPassives",
            itemEquipKey = "passives",
            itemDirectKey = "directPassives"
        },
        
        infoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
            { key = "description", label = "Description", formatter = function(value)
                if not value then return "" end
                local cleanDescription = value:gsub("</?LSTag[^>]*>", ""):gsub("<[Bb][Rr]>", "\n")
                return "\n\t" .. cleanDescription:gsub(";", "\n\t"):gsub("%. ", ".\n\t")
            end },
            { key = "boosts", label = "Boosts", formatter = function(value)
                if not value then return "" end
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "conditions", label = "Conditions", formatter = function(value)
                if not value then return "" end
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "modName", label = "Mod Name" },
        }
    }

    local instance = ModifiableStatTab:New(holder, parentUI, config)
    setmetatable(instance, PassiveTab)
    return instance
end

return PassiveTab