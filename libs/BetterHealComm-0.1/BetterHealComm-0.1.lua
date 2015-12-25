
local MAJOR_VERSION = "BetterHealComm-0.1"
local MINOR_VERSION = 1

if not AceLibrary then error(MAJOR_VERSION.." requires AceLibrary")end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION)then return end
if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION.." requires AceOO-2.0")end
if not AceLibrary:HasInstance("AceEvent-2.0") then error(MAJOR_VERSION.." requires AceEvent-2.0")end
if not AceLibrary:HasInstance("AceLocale-2.2") then error(MAJOR_VERSION.." requires AceLocale-2.2")end

local _, class = UnitClass("player")

BHC = CreateFrame("Frame")
local L = AceLibrary("AceLocale-2.2"):new("BetterHealComm-0.1")

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
local function UnitValidAssist(unitID)
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
    ["([%w%s:]+)"] = true, -- Spell name
    ["Rank (%d+)"] = true, -- Spell rank
    ["^Corpse of (%w+)$"] = true, -- Character name from corpse

    ["Healing Touch"] = true,
    -- Priest
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

BHC.currentSpell = {
    name = false,
    rank = false,
    target = false,
    amount = false
}

function BHC:SetCurrentSpell(name, rank, target, amount)
    self.currentSpell.name = name
    self.currentSpell.rank = rank
    self.currentSpell.target = target
    self.currentSpell.amount = amount
end

local DAMAGE = 0
local HEAL   = 1
local AOE    = 2

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

-- Class spells table
BHC.spells = {}
if class == "DRUID" then
    BHC.spells[L["Healing Touch"]] = {
        type = HEAL,
    }
elseif class == "PRIEST" then
    BHC.spells[L["Lesser Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(52,  2.1  / 3.5 * 0.0375 * 1  * 0.25),
        [2] = MakeSpellFunc(79,  2.9  / 3.5 * 0.0375 * 4  * 0.25),
        [3] = MakeSpellFunc(147, 2.51 / 3.5 * 0.0375 * 10 * 0.25)
    }
    BHC.spells[L["Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(319, 3 / 3.5 * 0.0375 * 16 * 0.25),
        [2] = MakeSpellFunc(471, 3 / 3.5),
        [3] = MakeSpellFunc(610, 3 / 3.5),
        [4] = MakeSpellFunc(759, 3 / 3.5)
    }
    BHC.spells[L["Greater Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(957,  3 / 3.5),
        [2] = MakeSpellFunc(1220, 3 / 3.5),
        [3] = MakeSpellFunc(1524, 3 / 3.5),
        [4] = MakeSpellFunc(1903, 3 / 3.5),
        [5] = MakeSpellFunc(2081, 3 / 3.5),
    }
    BHC.spells[L["Flash Heal"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(287, 1.5 / 3.5),
        [2] = MakeSpellFunc(287, 1.5 / 3.5),
        [3] = MakeSpellFunc(361, 1.5 / 3.5),
        [4] = MakeSpellFunc(440, 1.5 / 3.5),
        [5] = MakeSpellFunc(568, 1.5 / 3.5),
        [6] = MakeSpellFunc(705, 1.5 / 3.5),
        [7] = MakeSpellFunc(886, 1.5 / 3.5)
    }
    BHC.spells[L["Prayer of Healing"]] = {
        type = HEAL,
        [1] = MakeSpellFunc(3/3.5/3),
        [2] = MakeSpellFunc(3/3.5/3),
        [3] = MakeSpellFunc(3/3.5/3),
        [4] = MakeSpellFunc(3/3.5/3),
        [5] = MakeSpellFunc(3/3.5/3),
    }
    BHC.spells[L["Renew"]] = {
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
end

-- Known ranks table
BHC.knownRanks = {}
for k,_ in pairs(BHC.spells) do
    BHC.knownRanks[k] = 0
end

function BHC:UpdateKnownRanks()
    local i, name, rank, lastName, lastRank = 1, GetSpellName(1, "spell")
    while name do
        if lastName ~= name then
            if self.spells[lastName] then
                _,_,rank = find(lastRank, L["Rank (%d+)"])
                self.knownRanks[lastName] = tonumber(rank)
            end
        end
        i = i + 1
        lastName, lastRank, name, rank = name, rank, GetSpellName(i, "spell")
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

    self:HookWoWAPI()
end

function BHC:OnSpellCast(...)
    if event == "SPELLCAST_START" then
        local spell = self.spells[arg[1]]
        if spell then
        end
    elseif event == "SPELLCAST_INTERRUPTED" then
    elseif event == "SPELLCAST_FAILED" then
        local cancelCommand = arg[1]
    elseif event == "SPELLCAST_DELAYED" then
        local msDelay = arg[1]
    elseif event == "SPELLCAST_STOP" then
        local cancelCommand = arg[1]
    end

    print(
    "|cff7777ffname|r %s |cff7777ffrank|r %s "..
    "|cff7777fftarget|r %s |cff7777ffamount|r %s",
    self.currentSpell.name,self.currentSpell.rank,
    self.currentSpell.target,self.currentSpell.amount)
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

function BHC:HookWoWAPI()
    -- CastSpell
    -- @param id Spell index in spellbook
    -- @param bookType "spell" or "pet"
    local OldCastSpell = CastSpell
    local function NewCastSpell(id, bookType)
        OldCastSpell(id, bookType)
        local name, rank = GetSpellName(id, bookType)
        if SpellIsTargeting() then
            -- Spell on mouse
            self:SetSpell(name, rank, false, false)
        else
            -- Spell casting on current target
        end
    end
    CastSpell = NewCastSpell

    -- CastSpellByName
    -- @param name Localized spell name
    -- @param target Target or nil
    local OldCastSpellByName = CastSpellByName
    local function NewCastSpellByName(name, isSelfCast)
        OldCastSpellByName(name, isSelfCast)
        local _,_,rank = find(name, L["Rank (%d+)"])
        local _,_,name = find(name, L["([%w%s:]+)"])
        if self.spells[name] then
            rank = tonumber(rank) or self.knownRanks[name]
            local target = isSelfCast and "player" or "target"
            local amount = self.spells[name][rank](self.bonuses.healingSpellPower)
            if SpellIsTargeting() then
                self:SetCurrentSpell(name, rank, false, amount)
            elseif UnitValidAssist(target) then
                self:SetCurrentSpell(name, rank, target, amount)
            end
        end
    end
    CastSpellByName = NewCastSpellByName

    -- WorldFrame:OnMouseDown
    local OldOnMouseDown = WorldFrame:GetScript("OnMouseDown")
    local function NewOnMouseDown()
        OldOnMouseDown()
        -- Get target name
        local targetName
        if UnitName("mouseover") then
            -- Targetable
        elseif GameTooltipTextLeft1:IsVisible() then
            -- Dead: released
            _,_,targetName = find(GameTooltipTextLeft1:GetText(), L["^Corpse of (%w+)$"])
        end
    end
    WorldFrame:SetScript("OnMouseDown", NewOnMouseDown)
end

-- ----------------------------------------------------------------------------
-- API
-- ----------------------------------------------------------------------------

AceLibrary:Register(BHC, MAJOR_VERSION, MINOR_VERSION, activate, deactivate, external)
