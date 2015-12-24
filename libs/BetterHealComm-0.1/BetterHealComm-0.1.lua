
local MAJOR_VERSION = "BetterHealComm-0.1"
local MINOR_VERSION = 1

if not AceLibrary then error(MAJOR_VERSION.." requires AceLibrary")end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION)then return end
if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION.." requires AceOO-2.0")end
if not AceLibrary:HasInstance("AceEvent-2.0") then error(MAJOR_VERSION.." requires AceEvent-2.0")end
if not AceLibrary:HasInstance("AceLocale-2.2") then error(MAJOR_VERSION.." requires AceLocale-2.2")end

local BHC = CreateFrame("Frame")
local L = AceLibrary("AceLocale-2.2"):new("BetterHealComm-0.1")

local M_BLUE = "|cff7777ff[%s]|r"

local remove = table.remove
local concat = table.concat
local find = string.find

-- ----------------------------------------------------------------------------
-- Utility functions
-- ----------------------------------------------------------------------------

local function print(...)
    if getn(arg) > 0 then
        if arg[1] == false or not find(tostring(arg[1]), "%%") then
            if arg[1] == false then
                remove(arg,1)
            end
            local s, i = tostring(arg[1]), 2
            while arg[i] ~= nil do
                s = s..", "..tostring(arg[i])
                i = i + 1
            end
            DEFAULT_CHAT_FRAME:AddMessage(s)
        else
            DEFAULT_CHAT_FRAME:AddMessage(format(remove(arg,1),unpack(arg)))
        end
    end
end

-- ----------------------------------------------------------------------------
-- Locales
-- ----------------------------------------------------------------------------

L:RegisterTranslations("enUS", function() return {
    ["^Corpse of (%w+)$"] = true,

    ["Healing Touch"] = true,

    ["Flash Heal"] = true,
    ["Greater Heal"] = true
} end)

-- ----------------------------------------------------------------------------
-- Tables
-- ----------------------------------------------------------------------------

BHC.spells = {
    [L["Healing Touch"]] = {},

    [L["Flash Heal"]] = {},
    [L["Greater Heal"]] = {}
}

BHC.current_spell = {}

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
-- Event handlers
-- ----------------------------------------------------------------------------

function BHC:AceEvent_FullyInitialized()
    self:TriggerEvent("BetterHealComm_Enabled")
    self:RegisterEvent("SPELLCAST_START",       "OnSpellCast")
    self:RegisterEvent("SPELLCAST_INTERRUPTED", "OnSpellCast")
    self:RegisterEvent("SPELLCAST_FAILED",      "OnSpellCast")
    self:RegisterEvent("SPELLCAST_DELAYED",     "OnSpellCast")
    self:RegisterEvent("SPELLCAST_STOP",        "OnSpellCast")
end

function BHC:OnSpellCast(...)
    --print(unpack(arg))
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

local hookDebug = true

-- CastSpell
-- @param id Spell index in spellbook
-- @param bookType "spell" or "pet"
local OldCastSpell = CastSpell
local function NewCastSpell(id, bookType)
    OldCastSpell(id, bookType)
    local spellName, rank = GetSpellName(id, bookType)
    if hookDebug then
        print(format(M_BLUE,"CastSpell"),spellName,rank)
    end
end
CastSpell = NewCastSpell

-- CastSpellByName
-- @param name Localized spell name
-- @param target Target or nil
local OldCastSpellByName = CastSpellByName
local function NewCastSpellByName(name, target)
    OldCastSpellByName(name, target)
    if hookDebug then
        print(format(M_BLUE,"CastSpellByName"),name,target,UnitExists("target"))
    end
end
CastSpellByName = NewCastSpellByName

-- WorldFrame:OnMouseDown
local OldOnMouseDown = WorldFrame:GetScript("OnMouseDown")
local function NewOnMouseDown()
    OldOnMouseDown()
    local targetName
    if UnitName("mouseover") then
        -- Targetable
        targetName = UnitName("mouseover")
    elseif GameTooltipTextLeft1:IsVisible() then
        -- Corpse
        _,_,targetName = find(GameTooltipTextLeft1:GetText(), L["^Corpse of (%w+)$"])
    end
    if hookDebug then
        print(format(M_BLUE,"OnMouseDown"),targetName)
    end
end
WorldFrame:SetScript("OnMouseDown", NewOnMouseDown)

-- ----------------------------------------------------------------------------
-- API
-- ----------------------------------------------------------------------------

AceLibrary:Register(BHC, MAJOR_VERSION, MINOR_VERSION, activate, deactivate, external)
