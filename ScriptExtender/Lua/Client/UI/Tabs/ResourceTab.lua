local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class ResourceTab : BaseTab
---@field AddedResources table
---@field AddedResourcesArea ExtuiGroup
ResourceTab = {}
setmetatable(ResourceTab, { __index = BaseTab })
ResourceTab.__index = ResourceTab

function ResourceTab:New(holder)
    local config = {
        tabName = "Resources",
        tabNameHandle = "UCT_ResourceTab_Label",
        idPrefix = "Resource",
        fetchMessage = SMS.FetchResources,
        searchLabel = "Search Resources:",
        searchLabelHandle = "UCT_SearchResources_Label",
        noItemsText = "No resources found.",
        maxTableWidth = 3,
        amountOptions = {1, 5, 10, 50, 99}, -- Add common amount options
        filters = {}
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, ResourceTab) -- Re-set metatable to the child class

    local gridConfig = {
        headerText = LCL.Get("UCT_AddedResourcesHeader", "Added Resources"),
        noItemsText = LCL.Get("UCT_NoCustomResources", "This character has no custom resources added."),
        maxTableWidth = 3,
        idPrefix = "Resource",
        renderItem = function(cell, uuid, data)
            local name = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))
            if not name then return end
            
            local amount = HLP.GetAttr(data, "amount")
            local level = HLP.GetAttr(data, "level")

            local displayString = name
            if amount then displayString = displayString .. " (x" .. amount .. ")" end
            if level and level > 0 then displayString = displayString .. " [Lvl " .. level .. "]" end

            local shortName = displayString
            if HLP.Strlen(shortName) > 25 then shortName = HLP.Cut(shortName, 1, 25) .. "..." end

            local resourceButton = cell:AddButton(shortName .. "##AddedResource" .. uuid)
            local popup = cell:AddPopup("ManageResource" .. uuid)

            resourceButton.OnClick = function() popup:Open() end

            InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" }, { key = "description", label = "Description" }, { key = "amount", label = "Amount" }, { key = "level", label = "Level" }, { key = "maxLevel", label = "Max Level" } })
            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove") .. "##" .. uuid) 
            removeButton.OnClick = function() SMS.ManageResource:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1 }) end 
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    return instance
end

function ResourceTab:Init()
    self:GetAddedResources()
    -- This will create the search, pagination, and main areas and fetch the first page of all resources
    BaseTab.Init(self)
end

function ResourceTab:DrawGrid()
    UI_Utils.CreateItemGrid(self.MainArea, self.Items, {
        maxTableWidth = self.Config.maxTableWidth,
        idPrefix = "Resource",
        sizingFixedSame = false,
        renderItem = function(cell, uuid, data)
            local name = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))
            if name then
                local description = LCL.PreprocessXML(HLP.GetAttr(data, "description"))

                local shortName = name
                if HLP.Strlen(shortName) > 25 then
                    shortName = HLP.Cut(shortName, 1, 25) .. "..."
                end

                local resourceButton = cell:AddButton(shortName .. "##Resource" .. uuid)
                local popup = cell:AddPopup("AddResource" .. uuid)
                local amountPopup = cell:AddPopup("AddResourceAmountPopup_" .. uuid)
                local levelPopup = cell:AddPopup("AddResourceLevelPopup_" .. uuid)

                resourceButton.OnClick = function() popup:Open() end

                local actionsTable = popup:AddTable("ResourceActionsTable" .. uuid, 2)
                actionsTable.SizingFixedSame = false
                actionsTable.NoHostExtendX = true

                local row1 = actionsTable:AddRow()
                local addButton = row1:AddCell():AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb72", "Add") .. "##Add" .. uuid)
                local removeButton = row1:AddCell():AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove") .. "##Remove" .. uuid)
                
                local row2 = actionsTable:AddRow()
                local addForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_ResourceTab_AddForParty", "Add for Party") .. "##AddParty" .. uuid)
                local removeForPartyBtn = row2:AddCell():AddButton(LCL.Get("UCT_ResourceTab_RemoveForParty", "Remove for Party") .. "##RemoveParty" .. uuid)

                InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" }, { key = "description", label = "Description" }, { key = "maxLevel", label = "Max Level" } })

                removeButton.OnClick = function() SMS.ManageResource:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1 }) end

                addButton.OnClick = function()
                    UI_Utils.DestroyChildren(amountPopup)
                    amountPopup:AddText("Select Amount:")
                    amountPopup:AddSeparator()

                    for _, amount in ipairs(self.Config.amountOptions) do
                        local amountBtn = amountPopup:AddButton(tostring(amount))
                        amountBtn.OnClick = function()
                            if data.maxLevel and data.maxLevel > 0 then
                                UI_Utils.DestroyChildren(levelPopup)
                                levelPopup:AddText("Select Level (Max: " .. data.maxLevel .. "):")
                                levelPopup:AddSeparator()
                                for level = 1, data.maxLevel do
                                    local levelBtn = levelPopup:AddButton(tostring(level))
                                    levelBtn.OnClick = function() SMS.ManageResource:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, data=data, amount=amount, level=level }) end
                                end
                                levelPopup:Open()
                            else
                                SMS.ManageResource:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, data=data, amount=amount, level=0 })
                            end
                        end
                    end
                    amountPopup:Open()
                end

                addForPartyBtn.OnClick = function()
                    UI_Utils.DestroyChildren(amountPopup) -- Reuse amountPopup for party selection
                    amountPopup:AddText("Select Amount for Party:")
                    amountPopup:AddSeparator()

                    for _, amount in ipairs(self.Config.amountOptions) do
                        local amountBtn = amountPopup:AddButton(tostring(amount))
                        amountBtn.OnClick = function()
                            if data.maxLevel and data.maxLevel > 0 then
                                UI_Utils.DestroyChildren(levelPopup) -- Reuse levelPopup for party selection
                                levelPopup:AddText("Select Level for Party (Max: " .. data.maxLevel .. "):")
                                levelPopup:AddSeparator()
                                for level = 1, data.maxLevel do
                                    local levelBtn = levelPopup:AddButton(tostring(level))
                                    levelBtn.OnClick = function() SMS.AddResourceForParty:SendToServer({ ID = USERID, uuid = uuid, data = data, amount=amount, level=level }) end
                                end
                                levelPopup:Open()
                            else
                                SMS.AddResourceForParty:SendToServer({ ID = USERID, uuid = uuid, data = data, amount=amount, level=0 })
                            end
                        end
                    end
                    amountPopup:Open()
                end

                removeForPartyBtn.OnClick = function() SMS.RemoveResourceForParty:SendToServer({ ID = USERID, uuid = uuid }) end
            end
        end
    })
end

function ResourceTab:GetAddedResources()
    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
        self.ModificationGrid.Parent:AddText(LCL.Get("UCT_ResourceTab_SelectCharacter", "Select a character to see their added resources."))
        return
    end

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local addedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].resources) or {}
    self.ModificationGrid:Draw(addedForChar)
end

return ResourceTab