local ModifiableStatTab = Ext.Require("Client/UI/Tabs/ModifiableStatTab.lua")

---@class StatusTab : ModifiableStatTab
StatusTab = {}
setmetatable(StatusTab, { __index = ModifiableStatTab })
StatusTab.__index = StatusTab

function StatusTab:New(holder, parentUI)
    local config = {
        tabName = "Statuses",
        tabNameHandle = "UCT_StatusTab_Label",
        idPrefix = "Status",
        fetchMessage = SMS.FetchStatuses,
        searchLabel = "Search Statuses:",
        searchLabelHandle = "UCT_SearchStatuses_Label",
        noItemsText = "No statuses found.",
        maxTableWidth = 5,

        filters = { mod = true },

        -- ModifiableStatTab config
        statName = "Status",
        statNamePlural = "Statuses",
        statNameLowerPlural = "statuses",
        statUUIDKey = "statusUUID",
        addBtnLabel = "hc056102aefe641d4be93e011426432083", -- Apply
        removeBtnLabel = "hc056102aefe641d4be93e011426432084", -- Remove
        
        sms = {
            fetchModNames = SMS.FetchStatusModNames,
            add = SMS.ApplyStatus,
            remove = SMS.ApplyStatus,
            addForParty = SMS.ApplyStatusForParty,
            removeForParty = SMS.RemoveStatusForParty,
            addOnItemEquip = SMS.ApplyStatusToItem,
            removeFromItemEquip = SMS.RemoveStatusFromItem,
            addOnItemDirect = SMS.AddDirectStatusToItem,
            removeFromItemDirect = SMS.RemoveDirectStatusFromItem
        },
        
        vars = {
            charKey = "AppliedStatuses",
            itemEquipKey = "statuses",
            itemDirectKey = "directStatuses"
        },
        
        infoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
    }

    local instance = ModifiableStatTab:New(holder, parentUI, config)
    setmetatable(instance, StatusTab)
    return instance
end

return StatusTab
