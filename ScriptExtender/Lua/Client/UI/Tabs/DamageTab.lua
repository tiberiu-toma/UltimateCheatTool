local UIState = Ext.Require("Client/UI/UIState.lua")
local ModificationGrid = Ext.Require("Client/UI/Components/ModificationGrid.lua")

---@class DamageTab
---@field Tab ExtuiTabItem
---@field MainContent ExtuiGroup
---@field ModificationGrid ModificationGrid
---@field SelectedDamageType string
---@field SelectedDiceType number
---@field SelectedNumDice number
DamageTab = {}
DamageTab.__index = DamageTab

function DamageTab:New(holder)
    local instance = setmetatable({
        Tab = holder:AddTabItem(LCL.Get("UCT_DamageTab_Label", "Damage")),
        SelectedDamageType = "Fire",
        SelectedDiceType = 4,
        SelectedNumDice = 1,
    }, DamageTab)

    local gridConfig = {
        headerText = LCL.Get("UCT_DamageTab_AddedBoosts", "Added Damage Boosts"),
        noItemsText = LCL.Get("UCT_DamageTab_NoBoosts", "No custom damage boosts applied."),
        maxTableWidth = 3,
        idPrefix = "Damage",
        renderItem = function(cell, uniqueKey, data)
            local button = cell:AddButton(data.display .. "##AppliedDamage" .. uniqueKey)
            local popup = cell:AddPopup("ManageDamage" .. uniqueKey)
            button.OnClick = function() popup:Open() end

            local removeButton = popup:AddButton(LCL.Get("hb1787db13e1747e681ca4bad56e73bb73", "Remove"))
            removeButton.OnClick = function()
                if UIState.SelectedEquipment then
                    SMS.ManageDamageOnItem:SendToServer({
                        ID = USERID,                        
                        itemInstanceUUID = UIState.SelectedEquipment.instanceUUID,
                        uniqueKey = uniqueKey,
                        remove = 1
                    })
                end
            end
        end
    }
    instance.ModificationGrid = ModificationGrid:New(instance.Tab:AddGroup("AppliedDamageBoosts"), gridConfig)

    return instance
end

function DamageTab:Init()
    self:GetAddedDamage()
    self:Draw()
end

function DamageTab:GetAddedDamage()
    local equipmentData = UIState.SelectedEquipment
    if not equipmentData then
        UI_Utils.DestroyChildren(self.ModificationGrid.Parent)
        self.ModificationGrid.Parent:AddText(LCL.Get("UCT_NoItemSelected", "No item selected."))
        return
    end
    local modifiedEquipment = Ext.Vars.GetModVariables(ModuleUUID).ModifiedEquipment or {}
    -- Data is now stored per instance UUID
    local itemMods = modifiedEquipment[equipmentData.instanceUUID]
    local data = (itemMods and itemMods.damage) or {}
    self.ModificationGrid:Draw(data)
end

function DamageTab:Draw()
    if self.MainContent then
        UI_Utils.DestroyChildren(self.MainContent)
    else
        self.MainContent = self.Tab:AddGroup("DamageTabMainContent")
    end

    local equipmentData = UIState.SelectedEquipment
    if not equipmentData then
        self.MainContent:AddText(LCL.Get("UCT_NoItemSelected", "No item selected."))
        return
    end

    -- Only show the damage builder for weapons
    if equipmentData.modifierList ~= "Weapon" then
        self.MainContent:AddText(LCL.Get("UCT_DamageTab_OnlyOnWeapons", "Damage boosts can only be applied to weapons."))
        return
    end

    local builderGroup = self.MainContent:AddGroup("DamageBuilder")
    builderGroup:AddSeparatorText(LCL.Get("UCT_DamageTab_AddBoost", "Add Damage Boost"))

    -- Damage Type
    local damageTypeOptions = { "Bludgeoning", "Piercing", "Slashing", "Acid", "Cold", "Fire", "Force", "Lightning", "Necrotic", "Poison", "Psychic", "Radiant", "Thunder" }
    local selectedDamageIndex = 1
    for i, dtype in ipairs(damageTypeOptions) do
        if dtype == self.SelectedDamageType then
            selectedDamageIndex = i
            break
        end
    end
    builderGroup:AddText("Damage Type:")
    local typeCombo = builderGroup:AddCombo("##DamageType")
    typeCombo.Options = damageTypeOptions
    typeCombo.SelectedIndex = selectedDamageIndex - 1
    typeCombo.OnChange = function(combo)
        self.SelectedDamageType = damageTypeOptions[combo.SelectedIndex + 1]
    end

    -- Number of Dice
    local numDiceOptions = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
    local numDiceOptionsStr = {}
    for _, n in ipairs(numDiceOptions) do table.insert(numDiceOptionsStr, tostring(n)) end
    local selectedNumDiceIndex = 1
    for i, num in ipairs(numDiceOptions) do
        if num == self.SelectedNumDice then -- Compare number with number
            selectedNumDiceIndex = i
            break
        end
    end
    builderGroup:AddText("Number of Dice:")
    local numDiceCombo = builderGroup:AddCombo("##NumDice")
    numDiceCombo.Options = numDiceOptionsStr
    numDiceCombo.SelectedIndex = selectedNumDiceIndex - 1
    numDiceCombo.OnChange = function(combo)
        self.SelectedNumDice = tonumber(numDiceOptions[combo.SelectedIndex + 1])
    end

    -- Dice Type
    local diceTypeOptions = { "d4", "d6", "d8", "d10", "d12", "d20" }
    local selectedDiceTypeIndex = 1
    for i, dtype in ipairs(diceTypeOptions) do
        if tonumber(dtype:sub(2)) == self.SelectedDiceType then -- Compare number with number
            selectedDiceTypeIndex = i
            break
        end
    end
    builderGroup:AddText("Dice Type:")
    local diceTypeCombo = builderGroup:AddCombo("##DiceType")
    diceTypeCombo.Options = diceTypeOptions
    diceTypeCombo.SelectedIndex = selectedDiceTypeIndex - 1
    diceTypeCombo.OnChange = function(combo)
        local selectedString = diceTypeOptions[combo.SelectedIndex + 1]
        self.SelectedDiceType = tonumber(selectedString:sub(2))
    end

    local addButton = builderGroup:AddButton(LCL.Get("UCT_DamageTab_AddBoost", "Add Damage Boost"))
    addButton.OnClick = function()
        local boostString = string.format("WeaponDamage(%dd%d,%s)", self.SelectedNumDice, self.SelectedDiceType, self.SelectedDamageType)
        local displayString = string.format("%dd%d %s", self.SelectedNumDice, self.SelectedDiceType, self.SelectedDamageType)
        SMS.ManageDamageOnItem:SendToServer({
            ID = USERID,
            itemInstanceUUID = UIState.SelectedEquipment.instanceUUID,
            templateUUID = UIState.SelectedEquipment.id, -- Send template for re-application logic
            boostString = boostString,
            display = displayString
        })
    end
end

return DamageTab