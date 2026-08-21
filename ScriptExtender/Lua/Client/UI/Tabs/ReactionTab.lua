local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local UIState = Ext.Require("Client/UI/UIState.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class ReactionTab : BaseTab
---@field ModificationGrid ModificationGrid
ReactionTab = {}
setmetatable(ReactionTab, { __index = BaseTab })
ReactionTab.__index = ReactionTab

function ReactionTab:New(holder)
    local config = {
        tabName = "Reactions",
        tabNameHandle = "UCT_ReactionTab_Label",
        idPrefix = "Reaction",
        fetchMessage = SMS.FetchReactions,
        searchLabel = "Search Reactions:",
        searchLabelHandle = "UCT_SearchReactions_Label",
        noItemsText = "No reactions found.",
        maxTableWidth = 5,
        filters = { mod = true }
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, ReactionTab)

    local gridConfig = {
        headerText = "Learned Reactions",
        noItemsText = "This character has no custom learned reactions.",
        maxTableWidth = 5,
        idPrefix = "Reaction",
        renderItem = function(cell, uuid, reactionMod)
            local data = reactionMod.data
            local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
            local fullName = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

            if not fullName then return end

            local name = fullName
            if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

            local item = cell:AddImageButton("##LearnedReaction" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("ManageReaction" .. uuid)

            item.OnClick = function() popup:Open() end

            local infoFields = {}
            if data.id then table.insert(infoFields, { key = "id", label = "ID" }) end
            if data.displayName or data.fullName then table.insert(infoFields, { key = data.fullName and "fullName" or "displayName", label = "Name" }) end
            if data.cost then table.insert(infoFields, { key = "cost", label = "Cost" }) end

            InfoPopup:AddInfo(popup, data, infoFields)
            
            local removeBtn = popup:AddButton("Unlearn##" .. uuid)
            removeBtn.OnClick = function() SMS.ManageReaction:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1 }) end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.ModificationGridArea, gridConfig)

    SMS.FetchReactionModNames:SendToServer({ ID = USERID })

    return instance
end

function ReactionTab:Init()
    self:GetLearnedReactions()
    BaseTab.Init(self)
end

function ReactionTab:DrawGrid()
    UI_Utils.CreateItemGrid(self.MainArea, self.Items, {
        maxTableWidth = self.Config.maxTableWidth,
        idPrefix = "Reaction",
        sizingFixedSame = false,
        renderItem = function(cell, uuid, data)
            local icon = HLP.GetAttr(data, "icon") or "EC_Portrait_Generic"
            local name = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

            if name then
                local fullName = name
                if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

                local item = cell:AddImageButton("##Reaction" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
                cell:AddText(name)
                local popup = cell:AddPopup("AddReaction" .. uuid)

                item.OnClick = function() popup:Open() end

                local actionsTable = popup:AddTable("ReactionActionsTable" .. uuid, 2)
                actionsTable.SizingFixedSame = false
                actionsTable.NoHostExtendX = true

                local row1 = actionsTable:AddRow()
                local learnBtn = row1:AddCell():AddButton("Learn##Learn" .. uuid)
                local unlearnBtn = row1:AddCell():AddButton("Unlearn##Unlearn" .. uuid)

                data.fullName = fullName
                local infoFields = {}
                if data.id then table.insert(infoFields, { key = "id", label = "ID" }) end
                if data.fullName then table.insert(infoFields, { key = "fullName", label = "Name" }) end
                if data.description then table.insert(infoFields, { key = "description", label = "Description" }) end
                if data.modName then table.insert(infoFields, { key = "modName", label = "Mod Name" }) end
                if data.cost then table.insert(infoFields, { key = "cost", label = "Cost" }) end

                InfoPopup:AddInfo(popup, data, infoFields)
                
                learnBtn.OnClick = function()
                    SMS.ManageReaction:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, data=data })
                end

                unlearnBtn.OnClick = function()
                    SMS.ManageReaction:SendToServer({ ID = USERID, character = UIState.SelectedCharacter, uuid=uuid, remove=1 })
                end
            end
        end
    })
end

function ReactionTab:GetLearnedReactions()
    local charUUID = UIState.SelectedCharacter
    if not charUUID then
        UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
        self.ModificationGrid.Parent:AddText("Select a character to see their learned reactions.")
        return
    end

    local modifiedChars = Ext.Vars.GetModVariables(ModuleUUID).CharacterModifications or {}
    local learnedForChar = (modifiedChars[charUUID] and modifiedChars[charUUID].reactions) or {}
    self.ModificationGrid:Draw(learnedForChar)
end

return ReactionTab