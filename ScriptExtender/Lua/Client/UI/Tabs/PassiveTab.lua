local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class PassiveTab : BaseTab
---@field AddedPassives table
---@field AddedPassivesArea ExtuiGroup
PassiveTab = {}
setmetatable(PassiveTab, { __index = BaseTab })
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
        filters = { mod = true }
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, PassiveTab) -- Re-set metatable to the child class
    instance.ParentUI = parentUI

    local gridConfig = {
        headerText = LCL.Get("UCT_AddedPassivesHeader", "Added Passives"),
        noItemsText = LCL.Get("UCT_NoCustomPassives", "No custom passives."),
        maxTableWidth = 3,
        idPrefix = "Passive",
        renderItem = function(cell, uniqueKey, data)
            local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
            if icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
            local fullName = HLP.GetAttr(data, "displayName")

            if not fullName then return end

            local name = fullName
            if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

            if data.source then
                name = name .. " (" .. data.source .. ")"
            end

            local itemButton = cell:AddImageButton("##PassiveGrid" .. uniqueKey, icon, {100 * ViewPortScale, 100 * ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("ManagePassive_" .. uniqueKey)

            itemButton.OnClick = function() popup:Open() end

            InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" } })

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                if instance.ParentUI == "CharacterTools" then
                    -- For characters, the uniqueKey is just the passive UUID.
                    SMS.AddPassive:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uniqueKey, remove = 1 })
                elseif instance.ParentUI == "ItemTools" and UIState.SelectedEquipment then
                    -- For items, the key is composite: passiveUUID_sourceType
                    local passiveUUID, sourceType = uniqueKey:match("^(.*)_(.*)$")
                    if passiveUUID and sourceType then
                        if sourceType == "equip" then
                            SMS.RemovePassiveFromItem:SendToServer({ ID = USERID, itemInstanceUUID = UIState.SelectedEquipment.instanceUUID, templateUUID = UIState.SelectedEquipment.id, passiveUUID = passiveUUID })
                        elseif sourceType == "direct" then
                            SMS.RemoveDirectPassiveFromItem:SendToServer({ ID = USERID, itemInstanceUUID = UIState.SelectedEquipment.instanceUUID, passiveUUID = passiveUUID })
                        end
                    end
                end
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    SMS.FetchPassiveModNames:SendToServer({ ID = USERID })

    return instance
end

function PassiveTab:Init()
    self:GetAddedPassives()

    -- This will create the search, pagination, and main areas and fetch the first page of all passives
    BaseTab.Init(self)
end

function PassiveTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("PassiveGrid", tableWidth)
    t.SizingFixedSame = false
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end

        local icon = HLP.GetAttr(data, "icon")
        if not icon or icon == "unknown" or icon == "" then
            icon = "EC_Portrait_Generic"
        end
        local name = HLP.GetAttr(data, "displayName")
        if not name then
            goto continue
        end

        local fullName = name
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local passiveItem = cell:AddImageButton("##Passive" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddPassive" .. uuid)

        passiveItem.OnClick = function()
            popup:Open()
        end

        local actionsTable = popup:AddTable("PassiveActionsTable" .. uuid, 2)
        actionsTable.SizingFixedSame = false
        actionsTable.NoHostExtendX = true

        if self.ParentUI == "CharacterTools" then
            local row1 = actionsTable:AddRow()
            local addPassiveBtn = row1:AddCell():AddButton(LCL.Get("UCT_PassiveTab_Add", "Add") .. "##Add" .. uuid)
            local removePassiveBtn = row1:AddCell():AddButton(LCL.Get("UCT_PassiveTab_Remove", "Remove") .. "##Remove" .. uuid)

            local row2 = actionsTable:AddRow()
            local addForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_PassiveTab_AddForParty", "Add for Party") .. "##AddParty" .. uuid)
            local removeForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_PassiveTab_RemoveForParty", "Remove for Party") .. "##RemoveParty" .. uuid)

            addPassiveBtn.OnClick = function()
                SMS.AddPassive:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, amount = 1, data = data })
            end
            removePassiveBtn.OnClick = function()
                SMS.AddPassive:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
            end
            addForPartyBtn.OnClick = function()
                SMS.AddPassiveForParty:SendToServer({ ID = USERID, uuid = uuid, data = data })
            end
            removeForPartyBtn.OnClick = function()
                SMS.RemovePassiveForParty:SendToServer({ ID = USERID, uuid = uuid })
            end
        elseif self.ParentUI == "ItemTools" then
            local equipmentData = UIState.SelectedEquipment

            -- Method 1: Equip Effect
            popup:AddSeparatorText(LCL.Get("UCT_PassiveTab_AddAsEquipEffect", "As Equip Effect (On Wielder)"))
            popup:AddText(LCL.Get("UCT_PassiveTab_EquipEffectDesc", "Applies to the character when equipped. Standard method."))
            local equipEffectTable = popup:AddTable("PassiveEquipEffectActions" .. uuid, 2)
            local equipEffectRow = equipEffectTable:AddRow()
            local addEquipEffectBtn = equipEffectRow:AddCell():AddButton(LCL.Get("UCT_PassiveTab_Add", "Add") .. "##AddEquipEffect" .. uuid)
            local removeEquipEffectBtn = equipEffectRow:AddCell():AddButton(LCL.Get("UCT_PassiveTab_Remove", "Remove") .. "##RemoveEquipEffect" .. uuid)

            popup:AddSeparator()

            -- Method 2: Direct Boost
            popup:AddSeparatorText(LCL.Get("UCT_PassiveTab_AddAsDirectBoost", "As Direct Boost (On Item)"))
            popup:AddText(LCL.Get("UCT_PassiveTab_DirectBoostDesc", "Applies directly to the item. Experimental, may have unintended effects."))
            local directBoostTable = popup:AddTable("PassiveDirectBoostActions" .. uuid, 2)
            local directBoostRow = directBoostTable:AddRow()
            local addDirectBoostBtn = directBoostRow:AddCell():AddButton(LCL.Get("UCT_PassiveTab_Add", "Add") .. "##AddDirectBoost" .. uuid)
            local removeDirectBoostBtn = directBoostRow:AddCell():AddButton(LCL.Get("UCT_PassiveTab_Remove", "Remove") .. "##RemoveDirectBoost" .. uuid)

            if not equipmentData then
                addEquipEffectBtn.Disabled = true
                removeEquipEffectBtn.Disabled = true
                addDirectBoostBtn.Disabled = true
                removeDirectBoostBtn.Disabled = true
            else
                -- Equip Effect (current logic)
                addEquipEffectBtn.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.AddPassiveOnItem:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, passiveUUID = uuid, data = data })
                    end
                end
                removeEquipEffectBtn.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.RemovePassiveFromItem:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, passiveUUID = uuid })
                    end
                end

                -- Direct Boost (new logic)
                addDirectBoostBtn.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.AddDirectPassiveToItem:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, passiveUUID = uuid, data = data })
                    end
                end
                removeDirectBoostBtn.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.RemoveDirectPassiveFromItem:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, passiveUUID = uuid })
                    end
                end
            end
        end

        data.fullName = fullName
        local passiveInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
            { key = "description", label = "Description", formatter = function(value)
                local cleanDescription = value:gsub("</?LSTag[^>]*>", ""):gsub("<[Bb][Rr]>", "\n")
                return "\n\t" .. cleanDescription:gsub(";", "\n\t"):gsub("%. ", ".\n\t")
            end },
            { key = "boosts", label = "Boosts", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "conditions", label = "Conditions", formatter = function(value)
                return "\n\t" .. value:gsub(";", "\n\t")
            end },
            { key = "modName", label = "Mod Name" },
        }
        InfoPopup:AddInfo(popup, data, passiveInfoFields)

        i = i + 1

        ::continue::
    end
end

function PassiveTab:GetAddedPassives()
    if self.ParentUI == "CharacterTools" then
        local charUUID = UIState.SelectedCharacter
        if not charUUID then
            UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
            self.ModificationGrid.Parent:AddText(LCL.Get("UCT_SelectCharacter", "Select a character."))
            return
        end
        local addedPassives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}
        local data = addedPassives[charUUID] or {}
        self.ModificationGrid:Draw(data)
    elseif self.ParentUI == "ItemTools" then
        local equipmentData = UIState.SelectedEquipment
        if not equipmentData then
            UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
            self.ModificationGrid.Parent:AddText(LCL.Get("UCT_NoItemSelected", "No item selected."))
            return
        end
        local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
        local itemMods = modifiedEquipment[equipmentData.instanceUUID] or {}

        local allPassives = {}
        -- Add passives from equip effect
        if itemMods.passives then
            for uuid, data in pairs(itemMods.passives) do
                local d = HLP.Merge({}, data) -- Create a copy to avoid modifying the persisted data
                d.source = "Equip"
                allPassives[uuid .. "_equip"] = d
            end
        end
        -- Add passives from direct boost
        if itemMods.directPassives then
            for uuid, pdata in pairs(itemMods.directPassives) do
                local d = HLP.Merge({}, pdata.data) -- Create a copy
                d.source = "Direct"
                allPassives[uuid .. "_direct"] = d
            end
        end
        self.ModificationGrid:Draw(allPassives)
    end
end

return PassiveTab