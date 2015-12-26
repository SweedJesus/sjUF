
local MAJOR_VERSION = "BetterHealComm-0.1"
local MINOR_VERSION = 1

if not AceLibrary then error(MAJOR_VERSION.." requires AceLibrary")end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION)then return end
if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION.." requires AceOO-2.0")end
if not AceLibrary:HasInstance("AceEvent-2.0") then error(MAJOR_VERSION.." requires AceEvent-2.0")end
if not AceLibrary:HasInstance("AceLocale-2.2") then error(MAJOR_VERSION.." requires AceLocale-2.2")end

local BHC = CreateFrame("Frame")
BHC.tooltip = CreateFrame("GameTooltip", "BHCTooltip", nil, "GameTooltipTemplate")
BHC.tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local L = AceLibrary("AceLocale-2.2"):new("BetterHealComm-0.1")

local _, class = UnitClass("player")

local remove = table.remove
local concat = table.concat
local find = string.find

-- ----------------------------------------------------------------------------
-- Utility functions
-- ----------------------------------------------------------------------------

local function print(...)
    if getn(arg) > 0 then
        for i=1,20 do
            arg[i] = tostring(arg[i])
        end
        if find(tostring(arg[1]), "%%") then
            DEFAULT_CHAT_FRAME:AddMessage("|cff77ff77[BHC]|r "..format(remove(arg,1),unpack(arg)))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff77ff77[BHC]|r "..concat(arg," "))
        end
    end
end

local function istable(val)
    return type(val)=="table"
end

-- @param unitID Unit identifier string
-- @return true if unitID is visible and connected, else false
-- @return true if unitID is assistable, else false
local function UnitIsValidAssist(unitID)
    return
    UnitIsVisible(unitID) and UnitIsConnected(unitID),
    1 == UnitCanAssist("player", unitID)
end

-- ----------------------------------------------------------------------------
-- activate, external, Enable, Disable
-- ----------------------------------------------------------------------------

-- Called when this library is fully activated
local function activate(self, oldLib, oldDeactivate)
    BetterHealComm = self
    self.SingleHeals = oldLib and oldLib.SingleHeals or {}
    self.GroupHeals  = oldLib and oldLib.GroupHeals or {}
    self.Hots        = oldLib and oldLib.Hots or {}
    self.Resses      = oldLib and oldLib.Resses or {}
    if oldDeactivate then oldDeactivate(oldLib) end
end

local function deactivate(oldLib)
    oldLib:UnregisterAlLEvents()
    oldLib:CancelAllScheduledEvents()
end

local AceEvent

-- Called when a new library is initially registered
local function external(self, major, instance)
    if major == "AceEvent-2.0" then
        AceEvent = instance
        AceEvent:embed(self)
        -- AceEvent setup
        self:UnregisterAllEvents()
        self:CancelAllScheduledEvents()
        if AceEvent:IsFullyInitialized() then
            self:RegisterEvents()
        else
            self:RegisterEvent("AceEvent_FullyInitialized")
        end
    end
end

-- ----------------------------------------------------------------------------
-- Locales
-- ----------------------------------------------------------------------------

L:RegisterTranslations("enUS", function() return {
    -- Search patterns
    ["([%w%s:]+)"] = true, -- Spell name
    ["Rank (%d+)"] = true, -- Spell rank
    ["^Corpse of (%w+)$"] = true, -- Character name from corpse
    -- Druid
    ["Healing Touch"] = true,
    ["Regrowth"] = true,
    ["Rejuvenation"] = true,
    -- Priest
    ["Resurrection"] = true,
    ["Lesser Heal"] = true,
    ["Heal"] = true,
    ["Greater Heal"] = true,
    ["Flash Heal"] = true,
    ["Prayer of Healing"] = true,
    ["Renew"] = true
} end)

-- ----------------------------------------------------------------------------
-- Tables
-- ----------------------------------------------------------------------------

local DAMAGE = 0
local HEAL   = 1
local HOT    = 2
local AOE    = 4
local RES    = 8

BHC.currentSpell = {
    name = false,
    rank = false,
    target = false,
    targetName = false,
    amount = false
}

function BHC:SetCurrentSpell(name, rank, target, targetName)
    name = name == nil and self.currentSpell.name or name
    rank = rank == nil and self.currentSpell.rank or rank

    self.currentSpell.name = name
    self.currentSpell.rank = rank
    self.currentSpell.target = target == nil and self.currentSpell.target or target
    self.currentSpell.targetName = targetName == nil and self.currentSpell.targetName or targetName

    if name and self.spells[name] then
        local spellType = self.spells[name].type
        if mod(spellType, RES) == 0 then
            print("Is resurrect")
        elseif mod(spellType, HEAL) == 0 then
            if mod(spellType, AOE) == 0 then
                print("Is AoE heal")
            else
                print("Is single heal")
                local bonus = self.bonuses.healingSpellPower
                print("|cff0000",bonus)
                self.currentSpell.amount = self.spells[name][rank](bonus)
            end
        end
    else
        self.currentSpell.amount = false
    end
end

function BHC:GetCurrentSpell()
    return self.currentSpell.name, self.currentSpell.rank,
    self.currentSpell.target, self.currentSpell.targetName,
    self.currentSpell.amount
end

function BHC:PrintCurrentSpell()
    print("|cffff7777name|r %s |cffff7777rank|r %s |cffff7777target|r %s "..
    "|cffff7777targetName|r %s |cffff7777amount|r %s",self:GetCurrentSpell())
end

-- Note: Blizzard spell tooltips account for direct increases to base values
-- from talents!
-- e.g. Greater Heal (Rank 1) without Spritual Healing: 899
--      Greater heal (Rank 1) WITH Spiritual Healing: 988 (899 * 1.10)
--
-- Spell efficiency is equal to "spell-percent * rank-percent" unless the spell
-- level is under 20, in which "rank-percent = rank-percent * 0.0375 *
-- level-rank-learned * 0.25".

local function MakeSpellFunc(base, coef)
    return function(spellPower)
        local _,_,_,_,sgRank = GetTalentInfo(2,14)
        local _,spirit = UnitStat("player",5)
        local sgMod = spirit*5*sgRank/100
        local _,_,_,_,shRank = GetTalentInfo(2,15)
        local shMod = 2*shRank/100+1
        return shMod * base + coef * (spellPower + sgMod)
    end
end

-- Spells table
BHC.spells = {
    -- Druid
    [L["Healing Touch"]] = {
        type = HEAL,
        [1]  = MakeSpellFunc(45,   1.5 / 3.5 * 0.0375 * 1 * 0.25),
        [2]  = MakeSpellFunc(101,  2 / 3.5 * 0.0375 * 8 * 0.25),
        [3]  = MakeSpellFunc(220,  2.5 / 3.5 * 0.0375 * 14 * 0.25),
        [4]  = MakeSpellFunc(405,  1),
        [5]  = MakeSpellFunc(634,  1),
        [6]  = MakeSpellFunc(819,  1),
        [7]  = MakeSpellFunc(1029, 1),
        [8]  = MakeSpellFunc(1314, 1),
        [9]  = MakeSpellFunc(1657, 1),
        [10] = MakeSpellFunc(2061, 1),
        [11] = MakeSpellFunc(2473, 1)
    },
    [L["Regrowth"]] = {
        type = HEAL+HOT,
        -- Not account for HoT component yet!
        [1] = MakeSpellFunc(92,   0.325 * 0.0375 * 12 * 0.25),
        [2] = MakeSpellFunc(177,  0.325 * 0.0375 * 18 * 0.25),
        [3] = MakeSpellFunc(258,  0.325),
        [4] = MakeSpellFunc(340,  0.325),
        [5] = MakeSpellFunc(432,  0.325),
        [6] = MakeSpellFunc(564,  0.325),
        [7] = MakeSpellFunc(686,  0.325),
        [8] = MakeSpellFunc(858,  0.325),
        [9] = MakeSpellFunc(1062, 0.325)
    },
    [L["Rejuvenation"]] = {
        type = HOT,
        hotInterval = 3,
        [1]  = MakeSpellFunc(32,  0.8 * 0.0375 *  4 * 0.25),
        [2]  = MakeSpellFunc(56,  0.8 * 0.0375 * 10 * 0.25),
        [3]  = MakeSpellFunc(116, 0.8 * 0.0375 * 16 * 0.25),
        [4]  = MakeSpellFunc(180, 0.8),
        [5]  = MakeSpellFunc(244, 0.8),
        [6]  = MakeSpellFunc(304, 0.8),
        [7]  = MakeSpellFunc(388, 0.8),
        [8]  = MakeSpellFunc(488, 0.8),
        [9]  = MakeSpellFunc(608, 0.8),
        [10] = MakeSpellFunc(756, 0.8),
        [11] = MakeSpellFunc(888, 0.8)
    },
    -- Priest
    [L["Resurrection"]] = {
        type = RES
    },
    [L["Lesser Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(52,  2.1  / 3.5 * 0.0375 * 1  * 0.25),
        [2] = MakeSpellFunc(79,  2.9  / 3.5 * 0.0375 * 4  * 0.25),
        [3] = MakeSpellFunc(147, 2.51 / 3.5 * 0.0375 * 10 * 0.25)
    },
    [L["Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(319, 3 / 3.5 * 0.0375 * 16 * 0.25),
        [2] = MakeSpellFunc(471, 3 / 3.5),
        [3] = MakeSpellFunc(610, 3 / 3.5),
        [4] = MakeSpellFunc(759, 3 / 3.5)
    },
    [L["Greater Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(957,  3 / 3.5),
        [2] = MakeSpellFunc(1220, 3 / 3.5),
        [3] = MakeSpellFunc(1524, 3 / 3.5),
        [4] = MakeSpellFunc(1903, 3 / 3.5),
        [5] = MakeSpellFunc(2081, 3 / 3.5),
    },
    [L["Flash Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(287, 1.5 / 3.5),
        [2] = MakeSpellFunc(287, 1.5 / 3.5),
        [3] = MakeSpellFunc(361, 1.5 / 3.5),
        [4] = MakeSpellFunc(440, 1.5 / 3.5),
        [5] = MakeSpellFunc(568, 1.5 / 3.5),
        [6] = MakeSpellFunc(705, 1.5 / 3.5),
        [7] = MakeSpellFunc(886, 1.5 / 3.5)
    },
    [L["Prayer of Healing"]] = {
        type = HEAL+AOE,
        [1] = MakeSpellFunc(3/3.5/3),
        [2] = MakeSpellFunc(3/3.5/3),
        [3] = MakeSpellFunc(3/3.5/3),
        [4] = MakeSpellFunc(3/3.5/3),
        [5] = MakeSpellFunc(3/3.5/3)
    },
    [L["Renew"]] = {
        type = HEAL,
        [1]  = MakeSpellFunc(45,  1),
        [2]  = MakeSpellFunc(100, 1),
        [3]  = MakeSpellFunc(175, 1),
        [4]  = MakeSpellFunc(245, 1),
        [5]  = MakeSpellFunc(315, 1),
        [6]  = MakeSpellFunc(400, 1),
        [7]  = MakeSpellFunc(510, 1),
        [8]  = MakeSpellFunc(650, 1),
        [9]  = MakeSpellFunc(810, 1),
        [10] = MakeSpellFunc(970, 1)
    }
}

-- Known ranks table
BHC.knownRanks = {}
for k,_ in pairs(BHC.spells) do
    BHC.knownRanks[k] = 0
end

function BHC:UpdateKnownRanks()
    local i, name, rank = 1, GetSpellName(1, "spell")
    while name do
        if self.spells[name] then
            _,_,rank = find(rank, L["Rank (%d+)"])
            self.knownRanks[name] = tonumber(rank)
        end
        i = i + 1
        name, rank = GetSpellName(i, "spell")
    end
end

-- Gear bonuses table
BHC.bonuses = {
    spellPower = 0,
    healingSpellPower = 0
}

function BHC:UpdateBonuses()
    if BonusScanner then
        self.bonuses.healingSpellPower = BonusScanner:GetBonus("HEAL")
    else
    end
end

-- ----------------------------------------------------------------------------
-- Event handlers
-- ----------------------------------------------------------------------------

function BHC:AceEvent_FullyInitialized()
    self:TriggerEvent("BetterHealComm_Enabled")

    self:RegisterEvent("SPELLCAST_START",       "OnSpellCast")
    self:RegisterEvent("SPELLCAST_INTERRUPTED", "OnSpellCast")
    self:RegisterEvent("SPELLCAST_FAILED",      "OnSpellCast")
    self:RegisterEvent("SPELLCAST_DELAYED",     "OnSpellCast")
    self:RegisterEvent("SPELLCAST_STOP",        "OnSpellCast")

    self:UpdateKnownRanks()
    self:UpdateBonuses()

    for k,v in pairs(self.knownRanks) do
        print(k,v)
    end

    self:HookWoWAPI()
end

function BHC:OnSpellCast(...)
    if event == "SPELLCAST_START" then
        local spell = self.spells[arg[1]]
        if spell then
        end
    elseif event == "SPELLCAST_INTERRUPTED" then
        self:SetCurrentSpell(false, false, false, false)
    elseif event == "SPELLCAST_FAILED" then
        local cancelCommand = arg[1]
        self:SetCurrentSpell(false, false, false, false)
    elseif event == "SPELLCAST_DELAYED" then
        local msDelay = arg[1]
    elseif event == "SPELLCAST_STOP" then
        local cancelCommand = arg[1]
        self:SetCurrentSpell(false, false, false, false)
    end
    --print("|cffff77ff[%s]|r %s %s %s %s",event,self:GetCurrentSpell())
end

-- ----------------------------------------------------------------------------
-- Internals
-- ----------------------------------------------------------------------------


function BHC:UpdateSpellInformation(spellName)
end

-- @param caster Caster of heal
-- @param amount Amount to be healed
-- @param target Target to be healed
function BHC:StartHeal(caster, amount, target)
end

-- @param caster Caster of canceled heal
function BHC:StopHeal(caster)
end

-- @param caster Caster of heal
-- @param amount Amount to be healed
-- @param targets Table of targets to be healed
function BHC:StartGroupHeal(caster, amount, targets)
end

-- @param caster Caster of canceled heal
function BHC:StopGroupHeal(caster)
end

-- ----------------------------------------------------------------------------
-- Hook WoW API functions
-- ----------------------------------------------------------------------------
-- Hook functions that involve spells in targeting to pull information from:
-- CastSpell, CastSpellByName, SpellTargetUnit, SpellStopTargeting
-- TargetUnit, UseAction, WorldFrame:OnMouseDown

-- TODO: Decide if I want to check for all classes or just healing classes

function BHC:HookWoWAPI()
    -- CastSpell
    -- @param id Spell index in spellbook
    -- @param bookType "spell" or "pet"
    local OldCastSpell = CastSpell
    local function NewCastSpell(id, bookType)
        print("|cff7777ff[CastSpell]|r", id, bookType)
        OldCastSpell(id, bookType) -- Call old
        local name, rank = GetSpellName(id, bookType)
        if name and self.spells[name] then
            _,_,rank = find(rank, L["Rank (%d+)"])
            rank = tonumber(rank) or self.knownRanks[name]
            if SpellIsTargeting() then
                -- Spell on mouse
                self:SetCurrentSpell(name, rank, false)
            else
                -- Spell casting on current target
                self:SetCurrentSpell(name, rank, "target", UnitName("target"))
            end
        end

        self:PrintCurrentSpell()
    end
    CastSpell = NewCastSpell

    -- CastSpellByName
    -- @param name Localized spell name
    -- @param target Target or nil
    local OldCastSpellByName = CastSpellByName
    local function NewCastSpellByName(name, onSelf)
        print("|cff7777ff[CastSpellByName]|r", name, onSelf)
        OldCastSpellByName(name, onSelf) -- Call old
        local _,_,rank = find(name, L["Rank (%d+)"])
        local _,_,name = find(name, L["([%w%s:]+)"])
        if self.spells[name] then
            rank = tonumber(rank) or self.knownRanks[name]
            if rank > self.knownRanks[name] then
                rank = self.knownRanks[name]
            end
            if rank == 0 then
                return
            end
            local target = onSelf and "player" or "target"
            if SpellIsTargeting() then
                -- Spell now on cursor
                self:SetCurrentSpell(name, rank, false, false)
            else
                -- Casting single on target or AoE spell
                self:SetCurrentSpell(name, rank, target or false, UnitName(target) or false) end
            end

            self:PrintCurrentSpell()
        end
        CastSpellByName = NewCastSpellByName

        -- SpellTargetUnit
        -- @param unit UnitID to target with spell on cursor
        local OldSpellTargetUnit = SpellTargetUnit
        local function NewSpellTargetUnit(unit)
            print("|cff7777ff[SpellTargetUnit]|r", unit)
            if SpellIsTargeting() then
                self:SetCurrentSpell(nil, nil, unit, UnitName(unit))
            end
            OldSpellTargetUnit(unit) -- Call old

            self:PrintCurrentSpell()
        end
        SpellTargetUnit = NewSpellTargetUnit

        -- SpellStopTargeting
        local OldSpellStopTargeting = SpellStopTargeting
        local function NewSpellStopTargeting()
            print("|cff7777ff[SpellStopTargeting]|r")
            OldSpellStopTargeting() -- Call old
            self:SetCurrentSpell(false, false, false, false)

            self:PrintCurrentSpell()
        end
        SpellStopTargeting = NewSpellStopTargeting

        -- TargetUnit
        -- @param unit UnitID to target
        local OldTargetUnit = TargetUnit
        local function NewTargetUnit(unit)
            print("|cff7777ff[TargetUnit]|r", unit)
            if SpellIsTargeting() then
                self:SetCurrentSpell(nil, nil, unit, UnitName(unit))
            end
            OldTargetUnit(unit)

            self:PrintCurrentSpell()
        end
        TargetUnit = NewTargetUnit

        -- UseAction
        -- @param slot
        -- @param checkCursor
        -- @param onSelf
        local OldUseAction = UseAction
        local function NewUseAction(slot, checkCursor, onSelf)
            print("|cff7777ff[UseAction]|r", slot, checkCursor, onSelf)
            OldUseAction(slot, checkCursor, onSelf) -- Call old
            if not GetActionText(slot) then
                -- Isn't a macro
                self.tooltip:ClearLines()
                self.tooltip:SetAction(slot)
                local name = BHCTooltipTextLeft1:GetText()
                if self.spells[name] then
                    -- Is a spell we care about
                    local rank = BHCTooltipTextRight1:GetText()
                    _,_,rank = find(rank, L["Rank (%d+)"])
                    local target = onSelf and "player" or
                    UnitIsValidAssist("target") and "target"
                    self:SetCurrentSpell(name, tonumber(rank), target, UnitName(target))
                end
            end

            self:PrintCurrentSpell()
        end
        UseAction = NewUseAction

        -- WorldFrame:OnMouseDown
        local OldOnMouseDown = WorldFrame:GetScript("OnMouseDown")
        local function NewOnMouseDown()
            print("|cff7777ff[WorldFrame:OnMouseDown]|r")
            OldOnMouseDown() -- Call old
            --if SpellIsTargeting() then
            if UnitIsValidAssist("mouseover") then
                -- Targetable
                self:SetCurrentSpell(nil, nil, "target", UnitName("target"))
            elseif GameTooltipTextLeft1:IsVisible() then
                -- Corpse
                local _,_,targetName = find(GameTooltipTextLeft1:GetText(), L["^Corpse of (%w+)$"])
                self:SetCurrentSpell(nil, nil, "corpse", targetName)
            end
            --end
            self:PrintCurrentSpell()
        end
        WorldFrame:SetScript("OnMouseDown", NewOnMouseDown)
    end

    -- ----------------------------------------------------------------------------
    -- API
    -- ----------------------------------------------------------------------------

    AceLibrary:Register(BHC, MAJOR_VERSION, MINOR_VERSION, activate, deactivate, external)
