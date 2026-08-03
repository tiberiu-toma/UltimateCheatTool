local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class PassiveTab : BaseTab
---@field AddedPassives table
---@field AddedPassivesArea ExtuiGroup
PassiveTab = {}
setmetatable(PassiveTab, { __index = BaseTab })
PassiveTab.__index = PassiveTab

function PassiveTab:New(holder)
    if UI.PassiveTab then return end

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
    instance.AddedPassives = {}
    return instance
end

function PassiveTab:Init()
    self.AddedPassivesArea = self.Tab:AddGroup("AddedPassives")
    self:GetAddedPassives()

    -- This will create the search, pagination, and main areas and fetch the first page of all passives
    BaseTab.Init(self)
end

function PassiveTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("PassiveGrid", tableWidth)
    t.SizingFixedSame = true
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

        local addPassiveBtn = popup:AddButton(LCL.Get("UCT_PassiveTab_Add", "Add"))
        local removePassiveBtn = popup:AddButton(LCL.Get("UCT_PassiveTab_Remove", "Remove"))
        removePassiveBtn.SameLine = true

        local addForPartyBtn = popup:AddButton(LCL.Get("UCT_PassiveTab_AddForParty", "Add for Party"))
        local removeForPartyBtn = popup:AddButton(LCL.Get("UCT_PassiveTab_RemoveForParty", "Remove for Party"))
        removeForPartyBtn.SameLine = true

        local addToSelectedItem = popup:AddButton(LCL.Get("UCT_PassiveTab_AddToSelectedItem", "Add to Selected Item"))
        local removeFromSelectedItem = popup:AddButton(LCL.Get("UCT_PassiveTab_RemoveFromSelectedItem", "Remove from Selected"))
        removeFromSelectedItem.SameLine = true

        local equipmentData = UI.EquipmentSelector.SelectedEquipment
        if not equipmentData then
            addToSelectedItem.Disabled = true
            removeFromSelectedItem.Disabled = true
        else
            addToSelectedItem.OnClick = function()
                if equipmentData and equipmentData.id then
                    SMS.AddPassiveOnItem:SendToServer({ ID = USERID, character = UI.CharSelector.SelectedCharacter, itemTemplateUUID = equipmentData.id, passiveUUID = uuid, data = data })
                end
            end
            removeFromSelectedItem.OnClick = function()
                if equipmentData and equipmentData.id then
                    SMS.RemovePassiveFromItem:SendToServer({ ID = USERID, character = UI.CharSelector.SelectedCharacter, itemTemplateUUID = equipmentData.id, passiveUUID = uuid })
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
        
        removePassiveBtn.OnClick = function()
            SMS.AddPassive:SendToServer({ ID = USERID, character = UI.CharSelector.SelectedCharacter, uuid=uuid, remove=1})
        end

        addPassiveBtn.OnClick = function()
            SMS.AddPassive:SendToServer({ ID = USERID, character = UI.CharSelector.SelectedCharacter, uuid=uuid, amount=1, data=data })
        end

        addForPartyBtn.OnClick = function()
            SMS.AddPassiveForParty:SendToServer({ ID = USERID, uuid = uuid, data = data })
        end

        removeForPartyBtn.OnClick = function()
            SMS.RemovePassiveForParty:SendToServer({ ID = USERID, uuid = uuid })
        end

        i = i + 1

        ::continue::
    end
end

---@param parent ExtuiGroup
---@param passives table
---@param maxTableWidth number
---@param onRemove function
function PassiveTab:_DrawPassiveGrid(parent, passives, maxTableWidth, onRemove, gridId)
    local total = HLP.Count(passives)
    if total == 0 then
        return
    end

    local tableWidth = math.min(total, maxTableWidth)
    local t = parent:AddTable(gridId, tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row
    local drawnCount = 0
    local maxDrawn = 50 -- Performance cap

    for uuid, data in kpairs(passives) do
        if drawnCount >= maxDrawn then
            parent:AddText("...and more (list truncated for performance).")
            break
        end

        if (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end

        local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
        if icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
        local fullName = HLP.GetAttr(data, "displayName")

        if not fullName then goto continue end

        local name = fullName
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local passiveItem = cell:AddImageButton("##PassiveGrid" .. uuid, icon, {100 * ViewPortScale, 100 * ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("ManagePassive_" .. uuid)

        passiveItem.OnClick = function() popup:Open() end

        data.fullName = fullName
        local infoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, infoFields)

        local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
        removeButton.OnClick = function()
            onRemove(uuid, data)
        end

        i = i + 1
        drawnCount = drawnCount + 1
        ::continue::
    end
end

function PassiveTab:GetAddedPassives()
    self.AddedPassives = Ext.Vars.GetModVariables(ModuleUUID).AddedPassives or {}

    UI.DestroyChildren(self.AddedPassivesArea)

    local header = self.AddedPassivesArea:AddCollapsingHeader(LCL.Get("UCT_AddedPassivesHeader", "Added Passives"))

    local layoutTable = header:AddTable("AddedPassivesLayout", 2)
    layoutTable.SizingFixedSame = true
    layoutTable.NoHostExtendX = true

    local row = layoutTable:AddRow()
    local charPassivesCell = row:AddCell()
    local itemPassivesCell = row:AddCell()

    -- Column 1: Character Passives
    charPassivesCell:AddSeparatorText(LCL.Get("UCT_OnCharacter", "On Character"))
    local charUUID = UI.CharSelector and UI.CharSelector.SelectedCharacter
    if not charUUID then
        charPassivesCell:AddText(LCL.Get("UCT_SelectCharacter", "Select a character."))
    else
        local addedForChar = self.AddedPassives[charUUID] or {}
        if HLP.Count(addedForChar) == 0 then
            charPassivesCell:AddText(LCL.Get("UCT_NoCustomPassives", "No custom passives."))
        else
            self:_DrawPassiveGrid(charPassivesCell, addedForChar, 3, function(uuid, data)
                SMS.AddPassive:SendToServer({ ID = USERID, character = UI.CharSelector.SelectedCharacter, uuid = uuid, remove = 1 })
            end, "CharAddedPassivesGrid")
        end
    end

    -- Column 2: Item Passives
    itemPassivesCell:AddSeparatorText(LCL.Get("UCT_OnSelectedItem", "On Selected Item"))
    local equipmentData = UI.EquipmentSelector.SelectedEquipment
    if not equipmentData then
        itemPassivesCell:AddText(LCL.Get("UCT_NoItemSelected", "No item selected."))
    else
        local itemTemplateUUID = equipmentData.id
        local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
        local itemMods = modifiedEquipment[itemTemplateUUID]
        local itemPassives = itemMods and itemMods.passives

        if not itemPassives or HLP.Count(itemPassives) == 0 then
            itemPassivesCell:AddText(LCL.Get("UCT_NoCustomPassives", "No custom passives."))
        else
            self:_DrawPassiveGrid(itemPassivesCell, itemPassives, 3, function(uuid, data)
                SMS.RemovePassiveFromItem:SendToServer({ ID = USERID, character = UI.CharSelector.SelectedCharacter, itemTemplateUUID = itemTemplateUUID, passiveUUID = uuid })
            end, "ItemAddedPassivesGrid")
        end
    end
end

return PassiveTab