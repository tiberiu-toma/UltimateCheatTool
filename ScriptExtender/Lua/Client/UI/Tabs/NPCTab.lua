local BaseTab = Ext.Require("Client/UI/Tabs/BaseTab.lua")
local InfoPopup = Ext.Require("Client/Utils/InfoPopup.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class NPCTab : BaseTab
---@field SpawnedNPCs table
---@field SpawnedNPCsGrid ModificationGrid
NPCTab = {}
setmetatable(NPCTab, { __index = BaseTab })
NPCTab.__index = NPCTab

function NPCTab:New(holder)
    local config = {
        tabName = "NPCs",
        tabNameHandle = "UCT_NPCTab_Label",
        idPrefix = "NPC",
        fetchMessage = SMS.FetchNPCs,
        searchLabel = "Search NPCs:",
        searchLabelHandle = "UCT_SearchNPCs_Label",
        noItemsText = "No NPCs found.",
        maxTableWidth = 5
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, NPCTab) -- Re-set metatable to the child class
    instance.SpawnedNPCs = {}

    local spawnedGridArea = instance.Tab:AddGroup("SpawnedNPCs")

    local gridConfig = {
        headerText = LCL.Get("UCT_NPCTab_SpawnedNPCsHeader", "Spawned NPCs"),
        noItemsText = LCL.Get("UCT_NPCTab_NoSpawnedNPCs", "You haven't spawned any NPCs."),
        maxTableWidth = 5,
        idPrefix = "SpawnedNPC",
        renderItem = function(cell, uuid, data)
            local icon = "EC_Portrait_Generic"
            local fullName = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))
            if not fullName then return end

            local name = fullName
            if HLP.Strlen(name) > 20 then name = HLP.Cut(name, 1, 20) .. "..." end

            local npcItem = cell:AddImageButton("##SpawnedNPC" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
            cell:AddText(name)
            local popup = cell:AddPopup("ManageNPC" .. uuid)
            npcItem.OnClick = function() popup:Open() end

            InfoPopup:AddInfo(popup, data, { { key = "id", label = "ID" }, { key = "displayName", label = "Name" } })

            popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove") .. "##" .. uuid).OnClick = function() SMS.DespawnCharacter:SendToServer({ ID = USERID, uuid=uuid }) end
            popup:AddButton(LCL.Get("h684797ebd2ea4495b56dcc96c031bf261", "Enable Combat") .. "##" .. uuid).OnClick = function() SMS.ManageNPC:SendToServer({ ID = USERID, uuid=uuid,can=1,topic="combat" }) end
            popup:AddButton(LCL.Get("h684797ebd2ea4495b56dcc96c031bf262", "Disable Combat") .. "##" .. uuid).OnClick = function() SMS.ManageNPC:SendToServer({ ID = USERID, uuid=uuid,can=0,topic="combat" }) end
        end
    }
    instance.SpawnedNPCsGrid = ModificationGrid:New(spawnedGridArea, gridConfig)

    return instance
end

function NPCTab:Init()
    self:GetSpawnedNPCs()

    -- This will create the search, pagination, and main areas and fetch the first page of all NPCs
    BaseTab.Init(self)
end

function NPCTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("NPCGrid", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end
        
        local icon = "EC_Portrait_Generic"
        local fullName = LCL.PreprocessXML(HLP.GetAttr(data, "displayName"))

        if not fullName then goto continue end

        local name = fullName
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local npcItem = cell:AddImageButton("##NPC" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("AddItem" .. uuid)

        npcItem.OnClick = function()
            popup:Open()
        end

        local selectNPC = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn") .. "##" .. uuid)

        data.fullName = fullName
        local npcInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, npcInfoFields)

        selectNPC.OnClick = function()
            SMS.SpawnCharacter:SendToServer({ ID = USERID, uuid=uuid, amount=1, data=data })
        end

        i = i + 1

        ::continue::
    end
end

function NPCTab:GetSpawnedNPCs()
    self.SpawnedNPCs = Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs or {}
    self.SpawnedNPCsGrid:Draw(self.SpawnedNPCs)
end

return NPCTab