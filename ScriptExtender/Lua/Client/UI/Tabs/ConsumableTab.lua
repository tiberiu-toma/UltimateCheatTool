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
        local amountPopup = cell:AddPopup("SpawnAmountPopup_"..uuid)
        local targetPopup = cell:AddPopup("SpawnTargetPopup_"..uuid)

        itemButton.OnClick = function()
            popup:Open()
        end

        local spawnBtn = popup:AddButton(LCL.Get("UCT_SpawnAmountFor", "Spawn amount... for..."))
        spawnBtn.OnClick = function()
            -- 1. Configure and open the amount popup
            UI_Utils.DestroyChildren(amountPopup)
            
            if not (ItemTools and ItemTools.PartyMembers and #ItemTools.PartyMembers > 0) then
                amountPopup:AddText(LCL.Get("UCT_NoPartyMembers", "No party members found to spawn items for."))
                amountPopup:Open()
                return
            end

            amountPopup:AddText(LCL.Get("UCT_SelectSpawnAmount", "Select amount to spawn:"))
            amountPopup:AddSeparator()

            for _, amount in ipairs(self.Config.amountOptions) do
                local amountBtn = amountPopup:AddButton(tostring(amount))
                amountBtn.OnClick = function()
                    -- 2. An amount was clicked. Configure the target popup.
                    UI_Utils.DestroyChildren(targetPopup)
                    targetPopup:AddText(string.format(LCL.Get("UCT_SelectSpawnTargetForAmount", "Spawn %s for:"), tostring(amount)))
                    targetPopup:AddSeparator()

                    for _, member in ipairs(ItemTools.PartyMembers) do
                        local spawnForCharBtn = targetPopup:AddButton(member.name)
                        spawnForCharBtn.OnClick = function()
                            SMS.SpawnTemplate:SendToServer({ character = member.uuid, uuid = uuid, amount = amount })
                        end
                    end
                    targetPopup:AddSeparator()
                    local spawnForAllBtn = targetPopup:AddButton(LCL.Get("UCT_EntireParty", "Entire Party"))
                    spawnForAllBtn.OnClick = function()
                        SMS.SpawnAllOfTemplateForParty:SendToServer({ uuid = uuid, amount = amount })
                    end
                    
                    targetPopup:Open()
                end
            end
            
            amountPopup:Open()
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