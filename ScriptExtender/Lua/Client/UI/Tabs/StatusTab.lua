local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class StatusTab : BaseTab
---@field AppliedStatuses table
---@field AppliedStatusesArea ExtuiGroup
---@field ParentUI string
---@field ModificationGrid ModificationGrid
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
        maxTableWidth = 5,
        filters = { mod = true }
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, StatusTab) -- Re-set metatable to the child class
    instance.ParentUI = parentUI

    local gridConfig = {
        headerText = LCL.Get("UCT_AppliedStatusesHeader", "Applied Statuses"),
        noItemsText = LCL.Get("UCT_NoCustomStatuses", "No custom statuses."),
        maxTableWidth = 3,
        idPrefix = "Status",
        renderItem = function(cell, uuid, data)
            local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
            if icon == "unknown" or icon == "" then icon = "EC_Portrait_Generic" end
            local fullName = HLP.GetAttr(data, "displayName")

            if not fullName then return end

            local name = fullName
            if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

            local itemButton = cell:AddImageButton("##StatusGrid" .. uuid, icon, {100 * ViewPortScale, 100 * ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("ManageStatus_" .. uuid)

            itemButton.OnClick = function() popup:Open() end

            InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" } })

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                if instance.ParentUI == "CharacterTools" then
                    SMS.ApplyStatus:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid = uuid, remove = 1 })
                elseif instance.ParentUI == "ItemTools" and UIState.SelectedEquipment then
                    SMS.RemoveStatusFromItem:SendToServer({ ID = USERID, itemInstanceUUID = UIState.SelectedEquipment.instanceUUID, templateUUID = UIState.SelectedEquipment.id, statusUUID = uuid })
                end
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    SMS.FetchStatusModNames:SendToServer({ ID = USERID })

    return instance
end

function StatusTab:Init()
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
        
        if name then
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
                    SMS.ApplyStatus:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1 })
                end
        
                applyStatus.OnClick = function()
                    SMS.ApplyStatus:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, amount=1, data=data })
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

                local equipmentData = UIState.SelectedEquipment
                if not equipmentData then
                    applyToSelectedItem.Disabled = true
                    removeFromSelectedItem.Disabled = true
                else
                    applyToSelectedItem.OnClick = function()
                        if equipmentData and equipmentData.id then
                            SMS.ApplyStatusToItem:SendToServer({ ID = USERID, itemInstanceUUID = equipmentData.instanceUUID, templateUUID = equipmentData.id, statusUUID = uuid, data = data })
                        end
                    end
                    removeFromSelectedItem.OnClick = function()
                        if equipmentData and equipmentData.id then
                            SMS.RemoveStatusFromItem:SendToServer({ ID = USERID, itemInstanceUUID = UIState.SelectedEquipment.instanceUUID, templateUUID = UIState.SelectedEquipment.id, statusUUID = uuid })
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
        end
    end
end

function StatusTab:GetAppliedStatuses()
    if self.ParentUI == "CharacterTools" then
        local charUUID = UIState.SelectedCharacter
        if not charUUID then
            UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
            self.ModificationGrid.Parent:AddText(LCL.Get("UCT_SelectCharacter", "Select a character."))
            return
        end
        local appliedStatuses = Ext.Vars.GetModVariables(ModuleUUID).AppliedStatuses or {}
        local data = appliedStatuses[charUUID] or {}
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
        local data = (itemMods and itemMods.statuses) or {}
        self.ModificationGrid:Draw(data)
    end
end

return StatusTab