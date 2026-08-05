local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class EquipmentTab : BaseTab
EquipmentTab = {}
setmetatable(EquipmentTab, { __index = BaseTab })
EquipmentTab.__index = EquipmentTab

function EquipmentTab:New(holder)
    local config = {
        tabName = "Equipment",
        tabNameHandle = "UCT_EquipmentTab_Label",
        idPrefix = "Equipment",
        fetchMessage = SMS.FetchEquipment,
        searchLabel = "Search Equipment:",
        searchLabelHandle = "UCT_SearchEquipment_Label",
        noItemsText = "No equipment found.",
        maxTableWidth = 5,
        amountOptions = {1, 2, 5, 10, 99}
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, EquipmentTab) -- Re-set metatable to the child class
    return instance
end

function EquipmentTab:AddExtraSearchButtons(searchArea)
    local spawnAllBtn = searchArea:AddButton(LCL.Get("UCT_EquipmentTab_SpawnAll", "Spawn All (Non-Story)"))
    spawnAllBtn.OnClick = function()
        local charUUID = CharacterTools.CharSelector.SelectedCharacter
        SMS.SpawnAllEquipment:SendToServer({ ID = charUUID })
    end
end

function EquipmentTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("EquipmentGrid", tableWidth)
    t.SizingFixedSame = false
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end
        
        local icon = HLP.GetAttr(data, "icon")
        local name = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

        if not name then
            goto continue
        end

        local fullName = name
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local equipmentItem = cell:AddImageButton("##Equipment" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddItem" .. uuid)

        equipmentItem.OnClick = function()
            popup:Open()
        end
        
        local spawnTable = popup:AddTable("SpawnAmountTable" .. uuid, 5)
        spawnTable.SizingFixedSame = false
        spawnTable.NoHostExtendX = true
        local spawnRow = spawnTable:AddRow()

        for _,num in ipairs(self.Config.amountOptions) do
            local selectEquipment = spawnRow:AddCell():AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn") .. " " .. num .. "##Spawn" .. uuid .. tostring(num))

            selectEquipment.OnClick = function()
                local charUUID = CharacterTools.CharSelector.SelectedCharacter
                SMS.SpawnTemplate:SendToServer({ character = charUUID, uuid=uuid, amount=num })
            end
        end

        local setAsSelectedBtn = popup:AddButton(LCL.Get("UCT_EquipmentTab_SetAsSelected", "Set as Selected Equipment") .. "##SetSelected" .. uuid)
        setAsSelectedBtn.OnClick = function()
            if ItemTools and ItemTools.EquipmentSelector then
                ItemTools.EquipmentSelector:SetSelectedEquipment(data)
            end
        end

        data.fullName = fullName
        local equipmentInfoFields = {
            { key = "id", label = "ID", sameLine = false },
            { key = "fullName", label = "Name" },
            { key = "rarity", label = "Rarity" },
            { key = "armorClass", label = "Armor Class" },
            { key = "armorType", label = "Armor Type" },
            { key = "slot", label = "Slot" },
            { key = "defaultBoosts", label = "Default Boosts", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "boosts", label = "Boosts", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "boostsOnEquipMainHand", label = "Boosts on Equip (Main Hand)", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "boostsOnEquipOffHand", label = "Boosts on Equip (Off Hand)", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "passivesOnEquip", label = "Passives on Equip", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "modName", label = "Mod Name" },
        }
        InfoPopup:AddInfo(popup, data, equipmentInfoFields)

        i = i + 1

        ::continue::
    end

end

return EquipmentTab