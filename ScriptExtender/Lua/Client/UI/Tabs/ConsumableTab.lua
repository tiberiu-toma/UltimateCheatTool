local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")

---@class ConsumableTab : BaseTab
ConsumableTab = {}
setmetatable(ConsumableTab, { __index = BaseTab })
ConsumableTab.__index = ConsumableTab

function ConsumableTab:New(holder)
    local config = {
        tabName = "Consumables",
        tabNameHandle = "UCT_ConsumableTab_Label",
        idPrefix = "Consumable",
        fetchMessage = SMS.FetchConsumables,
        searchLabel = "Search Consumables:",
        searchLabelHandle = "UCT_SearchConsumables_Label",
        noItemsText = "No consumables found.",
        maxTableWidth = 5,
        amountOptions = {1, 2, 5, 10, 99}
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, ConsumableTab) -- Re-set metatable to the child class
    return instance
end

function ConsumableTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)
    
    local t = self.MainArea:AddTable("ConsumableGrid", tableWidth)
    t.SizingFixedSame = false
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end
        
        local icon = HLP.GetAttr(data, "icon")
        local fullName = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

        if not fullName then goto continue end

        local name = fullName
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local itemButton = cell:AddImageButton("##Consumable" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddItem" .. uuid)
        local spawnTargetPopup = cell:AddPopup("SpawnTarget_Consumable_" .. uuid)

        itemButton.OnClick = function()
            popup:Open()
        end

        local spawnForBtn = popup:AddButton(LCL.Get("UCT_SpawnFor", "Spawn For..."))
        spawnForBtn.OnClick = function()
            UI_Utils.DestroyChildren(spawnTargetPopup) -- Rebuild on open to get latest party
            if ItemTools and ItemTools.PartyMembers and #ItemTools.PartyMembers > 0 then
                for _, member in ipairs(ItemTools.PartyMembers) do
                    local spawnForCharBtn = spawnTargetPopup:AddButton(LCL.Get("UCT_SpawnForChar", "Spawn for") .. " " .. member.name)
                    spawnForCharBtn.OnClick = function()
                        SMS.SpawnTemplate:SendToServer({ character = member.uuid, uuid = uuid, amount = 1 })
                    end
                end
                spawnTargetPopup:AddSeparator()
                local spawnForAllBtn = spawnTargetPopup:AddButton(LCL.Get("UCT_SpawnForAll", "Spawn for Entire Party"))
                spawnForAllBtn.OnClick = function()
                    SMS.SpawnAllOfTemplateForParty:SendToServer({ uuid = uuid, amount = 1 })
                end
            end
            spawnTargetPopup:Open()
        end

        data.fullName = fullName
        local consumableInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, consumableInfoFields)

        i = i + 1

        ::continue::
    end
end

return ConsumableTab