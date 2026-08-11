local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")

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
        local charUUID = UIState.SelectedCharacter
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
        local spawnTargetPopup = cell:AddPopup("SpawnTarget_Equipment_" .. uuid)

        equipmentItem.OnClick = function()
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