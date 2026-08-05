local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class StatusTab : BaseTab
---@field AppliedStatuses table
---@field AppliedStatusesArea ExtuiGroup
StatusTab = {}
setmetatable(StatusTab, { __index = BaseTab })
StatusTab.__index = StatusTab

function StatusTab:New(holder, parentUI)
    local config = {
        tabName = "Statuses",
        tabNameHandle = "UCT_StatusTab_Label",
        idPrefix = "Status",
        fetchMessage = SMS.FetchStatuses,
        searchLabel = "Search Statuses:",
        searchLabelHandle = "UCT_SearchStatuses_Label",
        noItemsText = "No statuses found.",
        maxTableWidth = 5
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, StatusTab) -- Re-set metatable to the child class
    instance.AppliedStatuses = {}
    instance.ParentUI = parentUI -- Store the parent UI context
    return instance
end

function StatusTab:Init()
    self.AppliedStatusesArea = self.Tab:AddGroup("AppliedStatuses")
    self:GetAppliedStatuses()

    -- This will create the search, pagination, and main areas and fetch the first page of all statuses
    BaseTab.Init(self)
end

function StatusTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("StatusGrid", tableWidth)
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
        local statusItem = cell:AddImageButton("##Status" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddStatus" .. uuid)

        statusItem.OnClick = function()
            popup:Open()
        end

        local actionsTable = popup:AddTable("StatusActionsTable" .. uuid, 2)
        actionsTable.SizingFixedSame = false
        actionsTable.NoHostExtendX = true

        if self.ParentUI == "CharacterTools" then
            local row1 = actionsTable:AddRow()
            local applyStatus = row1:AddCell():AddButton(LCL.Get("hc056102aefe641d4be93e011426432083", "Apply") .. "##Apply" .. uuid)
            local removeStatus = row1:AddCell():AddButton(LCL.Get("hc056102aefe641d4be93e011426432084", "Remove") .. "##Remove" .. uuid)

            local row2 = actionsTable:AddRow()
            local applyForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_StatusTab_ApplyForParty", "Apply for Party") .. "##ApplyParty" .. uuid)
            local removeForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_StatusTab_RemoveForParty", "Remove for Party") .. "##RemoveParty" .. uuid)

            removeStatus.OnClick = function()
                SMS.ApplyStatus:SendToServer({ ID = USERID, character = CharacterTools.CharSelector.SelectedCharacter, uuid=uuid, remove=1 })
            end
    
            applyStatus.OnClick = function()
                SMS.ApplyStatus:SendToServer({ ID = USERID, character = CharacterTools.CharSelector.SelectedCharacter, uuid=uuid, amount=1, data=data })
            end
    
            applyForPartyBtn.OnClick = function()
                SMS.ApplyStatusForParty:SendToServer({ ID = USERID, uuid = uuid, data = data })
            end
    
            removeForPartyBtn.OnClick = function()
                SMS.RemoveStatusForParty:SendToServer({ ID = USERID, uuid = uuid })
            end

        elseif self.ParentUI == "ItemTools" then
            local row3 = actionsTable:AddRow()
            local applyToSelectedItem = row3:AddCell():AddButton(LCL.Get("UCT_StatusTab_ApplyToSelectedItem", "Apply to Selected Item") .. "##ApplyItem" .. uuid)
            local removeFromSelectedItem = row3:AddCell():AddButton(LCL.Get("UCT_StatusTab_RemoveFromSelectedItem", "Remove from Selected") .. "##RemoveItem" .. uuid)

            local equipmentData = ItemTools and ItemTools.EquipmentSelector and ItemTools.EquipmentSelector.SelectedEquipment
            if not equipmentData then
                applyToSelectedItem.Disabled = true
                removeFromSelectedItem.Disabled = true
            else
                applyToSelectedItem.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.ApplyStatusToItem:SendToServer({ ID = USERID, character = CharacterTools.CharSelector.SelectedCharacter, itemTemplateUUID = equipmentData.id, statusUUID = uuid, data = data })
                    end
                end
                removeFromSelectedItem.OnClick = function()
                    if equipmentData and equipmentData.id then
                        SMS.RemoveStatusFromItem:SendToServer({ ID = USERID, character = CharacterTools.CharSelector.SelectedCharacter, itemTemplateUUID = equipmentData.id, statusUUID = uuid })
                    end
                end
            end
        end

        data.fullName = fullName
        local statusInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, statusInfoFields)

        i = i + 1

        ::continue::
    end
end

---@param parent ExtuiGroup
---@param statuses table
---@param maxTableWidth number
---@param onRemove function
function StatusTab:_DrawStatusGrid(parent, statuses, maxTableWidth, onRemove, gridId)
    local total = HLP.Count(statuses)
    if total == 0 then
        return
    end

    local tableWidth = math.min(total, maxTableWidth)
    local t = parent:AddTable(gridId, tableWidth)
    t.SizingFixedFit = true
    t.NoHostExtendX = true

    local i = 1
    local row
    local drawnCount = 0
    local maxDrawn = 50 -- Performance cap

    for uuid, data in kpairs(statuses) do
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
        local statusItem = cell:AddImageButton("##StatusGrid" .. uuid, icon, {100 * ViewPortScale, 100 * ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("ManageStatus_" .. uuid)

        statusItem.OnClick = function() popup:Open() end

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

function StatusTab:GetAppliedStatuses()
    self.AppliedStatuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}

    UI_Utils.DestroyChildren(self.AppliedStatusesArea)

    local header = self.AppliedStatusesArea:AddCollapsingHeader(LCL.Get("UCT_AppliedStatusesHeader", "Applied Statuses"))

    local layoutTable = header:AddTable("AppliedStatusesLayout", 2)
    layoutTable.SizingFixedSame = true
    layoutTable.NoHostExtendX = true

    local row = layoutTable:AddRow()
    local charStatusesCell = row:AddCell()

    if self.ParentUI == "CharacterTools" then
        -- Column 1: Character Statuses
        charStatusesCell:AddSeparatorText(LCL.Get("UCT_OnCharacter", "On Character"))
        local charUUID = CharacterTools and CharacterTools.CharSelector and CharacterTools.CharSelector.SelectedCharacter
        if not charUUID then
            charStatusesCell:AddText(LCL.Get("UCT_SelectCharacter", "Select a character."))
        else
            local appliedForChar = self.AppliedStatuses[charUUID] or {}
            if HLP.Count(appliedForChar) == 0 then
                charStatusesCell:AddText(LCL.Get("UCT_NoCustomStatuses", "No custom statuses."))
            else
                self:_DrawStatusGrid(charStatusesCell, appliedForChar, 3, function(uuid, data)
                    SMS.ApplyStatus:SendToServer({ ID = USERID, character = CharacterTools.CharSelector.SelectedCharacter, uuid = uuid, remove = 1 })
                end, "CharAppliedStatusesGrid")
            end
        end
    elseif self.ParentUI == "ItemTools" then
        local itemStatusesCell = row:AddCell()
        -- Column 2: Item Statuses
        itemStatusesCell:AddSeparatorText(LCL.Get("UCT_OnSelectedItem", "On Selected Item"))
        local equipmentData = ItemTools and ItemTools.EquipmentSelector and ItemTools.EquipmentSelector.SelectedEquipment
        if not equipmentData then
            itemStatusesCell:AddText(LCL.Get("UCT_NoItemSelected", "No item selected."))
        else
            local itemTemplateUUID = equipmentData.id
            local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
            local itemMods = modifiedEquipment[itemTemplateUUID]
            local itemStatuses = itemMods and itemMods.statuses

            if not itemStatuses or HLP.Count(itemStatuses) == 0 then
                itemStatusesCell:AddText(LCL.Get("UCT_NoCustomStatuses", "No custom statuses."))
            else
                self:_DrawStatusGrid(itemStatusesCell, itemStatuses, 3, function(uuid, data)
                    SMS.RemoveStatusFromItem:SendToServer({ ID = USERID, character = CharacterTools.CharSelector.SelectedCharacter, itemTemplateUUID = itemTemplateUUID, statusUUID = uuid })
                end, "ItemAppliedStatusesGrid")
            end
        end
    end
end

return StatusTab