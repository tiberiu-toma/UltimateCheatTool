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
    setmetatable(instance, EquipmentTab)

    -- Add filter state
    instance.SelectedModifierList = "All"
    instance.SelectedSlot = "All"
    instance.SelectedRarity = "All"
    instance.SelectedModName = "All"
    
    -- Define filter options
    instance.ModifierListOptions = { "All", "Weapon", "Armor" }
    instance.SlotOptions = {
        "All", "Helmet", "Breast", "Gloves", "Boots", "Melee Main Weapon", 
        "Melee Offhand Weapon", "Ranged Main Weapon", "Ranged Offhand Weapon", 
        "Amulet", "Ring", "Ring2", "Underwear", "Cloak", "MusicalInstrument"
    }
    instance.RarityOptions = { "All", "Common", "Uncommon", "Rare", "VeryRare", "Legendary" }
    instance.ModNameOptions = { "All" } -- Will be populated from server

    -- Fetch mod names to populate the filter
    SMS.FetchEquipmentModNames:SendToServer({ ID = USERID })

    return instance
end

function EquipmentTab:FetchData(page)
    self.CurrentPage = page or 1
    local fetchMessage = self.Config.fetchMessage
    if fetchMessage then
        fetchMessage:SendToServer({ 
            ID = USERID, 
            search = self.SearchText, 
            page = self.CurrentPage,
            modifierList = self.SelectedModifierList,
            slot = self.SelectedSlot,
            rarity = self.SelectedRarity,
            modName = self.SelectedModName
        })
    end
end

function EquipmentTab:AddExtraSearchButtons(searchArea)
    local spawnAllBtn = searchArea:AddButton(LCL.Get("UCT_EquipmentTab_SpawnAll", "Spawn All (Non-Story)"))
    spawnAllBtn.OnClick = function()
        local charUUID = UIState.SelectedCharacter
        SMS.SpawnAllEquipment:SendToServer({ ID = charUUID })
    end

    searchArea:AddSeparator()
    searchArea:AddSeparatorText("Filters")
    local filterTable = searchArea:AddTable("EquipmentFilters", 8)
    filterTable.SizingFixedSame = false
    
    local row1 = filterTable:AddRow()

    row1:AddCell():AddText("Mod:")
    local selectedModNameIndex = 1
    for i, v in ipairs(self.ModNameOptions) do
        if v == self.SelectedModName then
            selectedModNameIndex = i
            break
        end
    end
    local modNameCombo = row1:AddCell():AddCombo("##ModNameFilter")
    modNameCombo.Options = self.ModNameOptions
    modNameCombo.SelectedIndex = selectedModNameIndex - 1
    modNameCombo.OnChange = function(combo)
        self.SelectedModName = self.ModNameOptions[combo.SelectedIndex + 1]
        self:FetchData(1)
    end

    row1:AddCell():AddText("Type:")
    local selectedModifierListIndex = 1
    for i, v in ipairs(self.ModifierListOptions) do
        if v == self.SelectedModifierList then
            selectedModifierListIndex = i
            break
        end
    end
    local modifierListCombo = row1:AddCell():AddCombo("##ModifierListFilter")
    modifierListCombo.Options = self.ModifierListOptions
    modifierListCombo.SelectedIndex = selectedModifierListIndex - 1
    modifierListCombo.OnChange = function(combo)
        self.SelectedModifierList = self.ModifierListOptions[combo.SelectedIndex + 1]
        self:FetchData(1)
    end

    row1:AddCell():AddText("Slot:")
    local selectedSlotIndex = 1
    for i, v in ipairs(self.SlotOptions) do
        if v == self.SelectedSlot then
            selectedSlotIndex = i
            break
        end
    end
    local slotCombo = row1:AddCell():AddCombo("##SlotFilter")
    slotCombo.Options = self.SlotOptions
    slotCombo.SelectedIndex = selectedSlotIndex - 1
    slotCombo.OnChange = function(combo)
        self.SelectedSlot = self.SlotOptions[combo.SelectedIndex + 1]
        self:FetchData(1)
    end

    row1:AddCell():AddText("Rarity:")
    local selectedRarityIndex = 1
    for i, v in ipairs(self.RarityOptions) do
        if v == self.SelectedRarity then
            selectedRarityIndex = i
            break
        end
    end
    local rarityCombo = row1:AddCell():AddCombo("##RarityFilter")
    rarityCombo.Options = self.RarityOptions
    rarityCombo.SelectedIndex = selectedRarityIndex - 1
    rarityCombo.OnChange = function(combo)
        self.SelectedRarity = self.RarityOptions[combo.SelectedIndex + 1]
        self:FetchData(1)
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

function EquipmentTab:SetModNameOptions(modNames)
    self.ModNameOptions = modNames
    self:AddSearch() -- Redraw search area to update the mod dropdown
end

return EquipmentTab