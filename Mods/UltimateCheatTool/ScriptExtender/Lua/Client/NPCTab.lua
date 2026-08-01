local BaseTab = Ext.Require("Client/BaseTab.lua")
local InfoPopup = Ext.Require("Client/InfoPopup.lua")

---@class NPCTab : BaseTab
---@field SpawnedNPCs table
---@field SpawnedNPCsArea ExtuiGroup
NPCTab = {}
setmetatable(NPCTab, { __index = BaseTab })
NPCTab.__index = NPCTab

function NPCTab:New(holder)
    if UI.NPCTab then return end 

    local config = {
        tabName = "NPCs",
        idPrefix = "NPC",
        fetchMessage = SMS.FetchNPCs,
        searchLabel = "Search NPCs:",
        noItemsText = "No NPCs found.",
        maxTableWidth = 5
    }

    local instance = BaseTab:New(holder, config)
    setmetatable(instance, NPCTab) -- Re-set metatable to the child class
    instance.SpawnedNPCs = {}
    return instance
end

function NPCTab:Init()
    self.SpawnedNPCs = Ext.Vars.GetModVariables(ModuleUUID).SpawnedNPCs or {}
    self.SpawnedNPCsArea = self.Tab:AddGroup("SpawnedNPCs")
    self:GetSpawnedNPCs()

    -- This will create the search, pagination, and main areas and fetch the first page of all NPCs
    BaseTab.Init(self)
end

function NPCTab:DrawGrid()
    local shownCount = HLP.Count(self.Items)
    local tableWidth = math.min(shownCount, self.Config.maxTableWidth)

    local t = self.MainArea:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.Items) do
        if (i - 1) % self.Config.maxTableWidth == 0 then
            row = t:AddRow()
        end
        
        local icon = HLP.GetAttr(data, "icon")
        if icon then
            icon = "EC_Portrait_Generic"
        end
        local fullName = HLP.GetAttr(data, "displayName")

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

        local selectNPC = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb75", "Spawn"))

        data.fullName = fullName
        local npcInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, npcInfoFields)

        selectNPC.OnClick = function()
            SMS.SpawnCharacter:SendToServer({ uuid=uuid, amount=1, data=data })

            self.SpawnedNPCs[uuid] = data
            self:GetSpawnedNPCs()
        end

        i = i + 1

        ::continue::
    end
end

function NPCTab:GetSpawnedNPCs()
    UI.DestroyChildren(self.SpawnedNPCsArea)

    local totalSpawned = HLP.Count(self.SpawnedNPCs)

    if totalSpawned == 0 then
        self.SpawnedNPCsArea:AddText("You haven't spawned any NPCs.")
        return
    end

    local maxTableWidth = self.Config.maxTableWidth or 5
    local tableWidth = math.min(totalSpawned, maxTableWidth)

    local header = self.SpawnedNPCsArea:AddCollapsingHeader("Spawned NPCs")

    local t = header:AddTable("", tableWidth)
    t.SizingFixedSame = true
    t.NoHostExtendX = true

    local i = 1
    local row

    for uuid,data in kpairs(self.SpawnedNPCs) do
        if (i - 1) % maxTableWidth == 0 then
            row = t:AddRow()
        end
        
        local icon = HLP.GetAttr(data, "icon")
        if icon then
            icon = "EC_Portrait_Generic"
        end
        local fullName = HLP.GetAttr(data, "displayName")

        if not fullName then
            goto continue
        end

        local name = fullName
        if HLP.Strlen(name) > 20 then
            name = HLP.Cut(name, 1, 20) .. "..."
        end

        local cell = row:AddCell()
        local npcItem = cell:AddImageButton("##SpawnedNPC" .. uuid, icon, {100*ViewPortScale, 100*ViewPortScale})
        cell:AddText(name)
        local popup = cell:AddPopup("ManageNPC" .. uuid)

        npcItem.OnClick = function()
            popup:Open()
        end

        data.fullName = fullName
        local spawnedNpcInfoFields = {
            { key = "id", label = "ID" },
            { key = "fullName", label = "Name" },
        }
        InfoPopup:AddInfo(popup, data, spawnedNpcInfoFields)

        local removeNPC = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
        local enableCombat = popup:AddButton(LCL.Get("h684797ebd2ea4495b56dcc96c031bf261", "Enable Combat"))
        local disableCombat = popup:AddButton(LCL.Get("h684797ebd2ea4495b56dcc96c031bf262", "Disable Combat"))

        removeNPC.OnClick = function()
            SMS.DespawnCharacter:SendToServer({ uuid=uuid })

            self.SpawnedNPCs[uuid] = nil
            self:GetSpawnedNPCs()
        end

        enableCombat.OnClick = function()
            SMS.ManageNPC:SendToServer({ uuid=uuid,can=1,topic="combat" })
        end
        disableCombat.OnClick = function()
            SMS.ManageNPC:SendToServer({ uuid=uuid,can=0,topic="combat" })
        end

        i = i + 1

        ::continue::
    end
end

return NPCTab