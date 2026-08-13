local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class ModifiableStatTab : BaseTab
---@field ParentUI string
---@field ModificationGrid ModificationGrid
ModifiableStatTab = {}
setmetatable(ModifiableStatTab, { __index = BaseTab })
ModifiableStatTab.__index = ModifiableStatTab

function ModifiableStatTab:New(holder, parentUI, config)
    -- The main config is now passed in, instead of being hardcoded in the child's New()
    local instance = BaseTab:New(holder, config)
    setmetatable(instance, ModifiableStatTab)
    instance.ParentUI = parentUI

    local gridConfig = {
        headerText = LCL.Get("UCT_Added" .. config.statNamePlural .. "Header", "Added " .. config.statNamePlural),
        noItemsText = LCL.Get("UCT_NoCustom" .. config.statNamePlural, "No custom " .. config.statNameLowerPlural .. "."),
        maxTableWidth = 3,
        idPrefix = config.statName,
        renderItem = function(cell, uniqueKey, data)
            instance:_RenderModificationGridItem(cell, uniqueKey, data)
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    -- Fetch mod names for filtering
    if config.sms.fetchModNames then
        config.sms.fetchModNames:SendToServer({ ID = USERID })
    end

    return instance
end

function ModifiableStatTab:_RenderModificationGridItem(cell, uniqueKey, data)
    local config = self.Config
    local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
    if icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
    local fullName = HLP.GetAttr(data, "displayName")

    if not fullName then return end

    local name = fullName
    if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

    if data.source then
        name = name .. " (" .. data.source .. ")"
    end

    local itemButton = cell:AddImageButton("##" .. config.statName .. "Grid" .. uniqueKey, icon, {100 * ViewPortScale, 100 * ViewPortScale})
    cell:AddText(name)
    local popup = cell:AddPopup("Manage" .. config.statName .. "_" .. uniqueKey)

    itemButton.OnClick = function() popup:Open() end

    InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" } })

    local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
    removeButton.OnClick = function()
        if self.ParentUI == "CharacterTools" then
            -- For characters, the uniqueKey is just the stat UUID.
            config.sms.remove:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uniqueKey, remove = 1 })
        elseif self.ParentUI == "ItemTools" and UIState.SelectedEquipment then
            -- For items, the key is composite: statUUID_sourceType
            local statUUID, sourceType = uniqueKey:match("^(.*)_(.*)$")
            if statUUID and sourceType then
                if sourceType == "equip" then
                    config.sms.removeFromItemEquip:SendToServer({ ID = USERID, itemInstanceUUID = UIState.SelectedEquipment.instanceUUID, templateUUID = UIState.SelectedEquipment.id, [config.statUUIDKey] = statUUID })
                elseif sourceType == "direct" then
                    config.sms.removeFromItemDirect:SendToServer({ ID = USERID, itemInstanceUUID = UIState.SelectedEquipment.instanceUUID, [config.statUUIDKey] = statUUID })
                end
            end
        end
    end
end

function ModifiableStatTab:Init()
    self:GetAppliedModifications()
    BaseTab.Init(self)
end

function ModifiableStatTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable(self.Config.statName .. "Grid", tableWidth)
    t.SizingFixedSame = false
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid, data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end

        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
        local name = HLP.GetAttr(data, "displayName")
        
        if name then
            local fullName = name
            if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

            local cell = row:AddCell()
            local item = cell:AddImageButton("##" .. self.Config.statName .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("Add" .. self.Config.statName .. uuid)

            item.OnClick = function() popup:Open() end

            if self.ParentUI == "CharacterTools" then
                self:_DrawCharacterActions(popup, uuid, data)
            elseif self.ParentUI == "ItemTools" then
                self:_DrawItemActions(popup, uuid, data)
            end

            data.fullName = fullName
            InfoPopup:AddInfo(popup, data, self.Config.infoFields)

            i = i + 1
        end
    end
end

function ModifiableStatTab:_DrawCharacterActions(popup, uuid, data)
    local config = self.Config
    local actionsTable = popup:AddTable(config.statName .. "ActionsTable" .. uuid, 2)
    actionsTable.SizingFixedSame = false
    actionsTable.NoHostExtendX = true

    local row1 = actionsTable:AddRow()
    local addBtn = row1:AddCell():AddButton(LCL.Get(config.addBtnLabel, "Add") .. "##Add" .. uuid)
    local removeBtn = row1:AddCell():AddButton(LCL.Get(config.removeBtnLabel, "Remove") .. "##Remove" .. uuid)

    local row2 = actionsTable:AddRow()
    local addForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_" .. config.statName .. "Tab_AddForParty", "Add for Party") .. "##AddParty" .. uuid)
    local removeForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_" .. config.statName .. "Tab_RemoveForParty", "Remove for Party") .. "##RemoveParty" .. uuid)

    addBtn.OnClick = function()
        config.sms.add:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, data = data })
    end
    removeBtn.OnClick = function()
        config.sms.remove:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
    end
    addForPartyBtn.OnClick = function()
        config.sms.addForParty:SendToServer({ ID = USERID, uuid = uuid, data = data })
    end
    removeForPartyBtn.OnClick = function()
        config.sms.removeForParty:SendToServer({ ID = USERID, uuid = uuid })
    end
end

function ModifiableStatTab:_DrawItemActions(popup, uuid, data)
    local config = self.Config
    local equipmentData = UIState.SelectedEquipment

    popup:AddSeparatorText(LCL.Get("UCT_" .. config.statName .. "Tab_AddAsEquipEffect", "As Equip Effect (On Wielder)"))
    popup:AddText(LCL.Get("UCT_" .. config.statName .. "Tab_EquipEffectDesc", "Applies to the character when equipped. Standard method."))
    local equipEffectTable = popup:AddTable(config.statName .. "EquipEffectActions" .. uuid, 2)
    local equipEffectRow = equipEffectTable:AddRow()
    local addEquipEffectBtn = equipEffectRow:AddCell():AddButton(LCL.Get(config.addBtnLabel, "Add") .. "##AddEquipEffect" .. uuid)
    local removeEquipEffectBtn = equipEffectRow:AddCell():AddButton(LCL.Get(config.removeBtnLabel, "Remove") .. "##RemoveEquipEffect" .. uuid)

    popup:AddSeparator()

    popup:AddSeparatorText(LCL.Get("UCT_" .. config.statName .. "Tab_AddAsDirectBoost", "As Direct Boost (On Item)"))
    popup:AddText(LCL.Get("UCT_" .. config.statName .. "Tab_DirectBoostDesc", "Applies directly to the item. Experimental, may have unintended effects."))
    local directBoostTable = popup:AddTable(config.statName .. "DirectBoostActions" .. uuid, 2)
    local directBoostRow = directBoostTable:AddRow()
    local addDirectBoostBtn = directBoostRow:AddCell():AddButton(LCL.Get(config.addBtnLabel, "Add") .. "##AddDirectBoost" .. uuid)
    local removeDirectBoostBtn = directBoostRow:AddCell():AddButton(LCL.Get(config.removeBtnLabel, "Remove") .. "##RemoveDirectBoost" .. uuid)

    if not equipmentData then
        addEquipEffectBtn.Disabled = true
        removeEquipEffectBtn.Disabled = true
        addDirectBoostBtn.Disabled = true
        removeDirectBoostBtn.Disabled = true
    else
        addEquipEffectBtn.OnClick = function()
            if equipmentData and equipmentData.id then
                config.sms.addOnItemEquip:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, [config.statUUIDKey] = uuid, data = data })
            end
        end
        removeEquipEffectBtn.OnClick = function()
            if equipmentData and equipmentData.id then
                config.sms.removeFromItemEquip:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, [config.statUUIDKey] = uuid })
            end
        end
        addDirectBoostBtn.OnClick = function()
            if equipmentData and equipmentData.id then
                config.sms.addOnItemDirect:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, [config.statUUIDKey] = uuid, data = data })
            end
        end
        removeDirectBoostBtn.OnClick = function()
            if equipmentData and equipmentData.id then
                config.sms.removeFromItemDirect:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, [config.statUUIDKey] = uuid })
            end
        end
    end
end

function ModifiableStatTab:GetAppliedModifications()
    local data = {}
    if self.ParentUI == "CharacterTools" then
        local charUUID = UIState.SelectedCharacter
        if not charUUID then
            UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
            self.ModificationGrid.Parent:AddText(LCL.Get("UCT_SelectCharacter", "Select a character."))
            return
        end
        local allMods = Ext.Vars.GetModVariables(ModuleUUID)[self.Config.vars.charKey] or {}
        data = allMods[charUUID] or {}
    elseif self.ParentUI == "ItemTools" then
        local equipmentData = UIState.SelectedEquipment
        if not equipmentData then
            UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
            self.ModificationGrid.Parent:AddText(LCL.Get("UCT_NoItemSelected", "No item selected."))
            return
        end
        local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
        local itemMods = modifiedEquipment[equipmentData.instanceUUID] or {}

        local equipMods = itemMods[self.Config.vars.itemEquipKey]
        if equipMods then
            for uuid, modData in pairs(equipMods) do
                local d = HLP.Merge({}, modData)
                d.source = "Equip"
                data[uuid .. "_equip"] = d
            end
        end
        local directMods = itemMods[self.Config.vars.itemDirectKey]
        if directMods then
            for uuid, modData in pairs(directMods) do
                local d = HLP.Merge({}, modData.data)
                d.source = "Direct"
                data[uuid .. "_direct"] = d
            end
        end
    end
    self.ModificationGrid:Draw(data)
end

return ModifiableStatTab