local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class ConsumableTab : BaseTab
ConsumableTab = {}
setmetatable(ConsumableTab, { __index = BaseTab })
ConsumableTab.__index = ConsumableTab

function ConsumableTab:New(holder)
    if UI.ConsumableTab then return end 

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

        itemButton.OnClick = function()
            popup:Open()
        end

        local spawnTable = popup:AddTable("SpawnAmountTable" .. uuid, 5)
        spawnTable.SizingFixedSame = false
        spawnTable.NoHostExtendX = true
        local spawnRow = spawnTable:AddRow()

        for _,num in ipairs(self.Config.amountOptions) do
            local selectConsumable = spawnRow:AddCell():AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn") .. " " .. num .. "##Spawn" .. uuid .. tostring(num))

            selectConsumable.OnClick = function()
                local charUUID = UI.CharSelector.SelectedCharacter
                SMS.SpawnTemplate:SendToServer({ character = charUUID, uuid=uuid, amount=num })
            end
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