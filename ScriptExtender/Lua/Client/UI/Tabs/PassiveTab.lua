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
        maxTableWidth = 5
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, PassiveTab) -- Re-set metatable to the child class
    instance.ParentUI = parentUI

    local gridConfig = {
        headerText = LCL.Get("UCT_AddedPassivesHeader", "Added Passives"),
        noItemsText = LCL.Get("UCT_NoCustomPassives", "No custom passives."),
        maxTableWidth = 3,
        idPrefix = "Passive",
        renderItem = function(cell, uuid, data)
            local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
            if icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
            local fullName = HLP.GetAttr(data, "displayName")

            if not fullName then return end

            local name = fullName
            if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

            local itemButton = cell:AddImageButton("##PassiveGrid" .. uuid, icon, {100 * ViewPortScale, 100 * ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("ManagePassive_" .. uuid)

            itemButton.OnClick = function() popup:Open() end

            InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" } })

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                if instance.ParentUI == "CharacterTools" then
                    SMS.AddPassive:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
                elseif instance.ParentUI == "ItemTools" and UIState.SelectedEquipment then
                    SMS.RemovePassiveFromItem:SendToServer({ ID = USERID, itemInstanceUUID = UIState.SelectedEquipment.instanceUUID, templateUUID = UIState.SelectedEquipment.id, passiveUUID = uuid })
                end
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.Tab:AddGroup("AddedPassives"), gridConfig)

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
                SMS.AddPassive:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, amount=1, data=data })
            end
            removePassiveBtn.OnClick = function()
                SMS.AddPassive:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1})
            end
            addForPartyBtn.OnClick = function()
                SMS.AddPassiveForParty:SendToServer({ ID = USERID, uuid = uuid, data = data })
            end
            removeForPartyBtn.OnClick = function()
                SMS.RemovePassiveForParty:SendToServer({ ID = USERID, uuid = uuid })
            end
        elseif self.ParentUI == "ItemTools" then
            local row3 = actionsTable:AddRow()
            local addToSelectedItem = row3:AddCell():AddButton(LCL.Get("UCT_PassiveTab_AddToSelectedItem", "Add to Selected Item") .. "##AddItem" .. uuid)
            local removeFromSelectedItem = row3:AddCell():AddButton(LCL.Get("UCT_PassiveTab_RemoveFromSelectedItem", "Remove from Selected") .. "##RemoveItem" .. uuid)

            local equipmentData = UIState.SelectedEquipment
            if not equipmentData then
                addToSelectedItem.Disabled = true
                removeFromSelectedItem.Disabled = true
            else
                addToSelectedItem.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.AddPassiveOnItem:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, passiveUUID = uuid, data = data })
                    end
                end
                removeFromSelectedItem.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.RemovePassiveFromItem:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, passiveUUID = uuid })
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
        local itemMods = modifiedEquipment[equipmentData.instanceUUID]
        local data = (itemMods and itemMods.passives) or {}
        self.ModificationGrid:Draw(data)
    end
end

return PassiveTab