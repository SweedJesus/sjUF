
local MAJOR_VERSION = "BetterHealComm-0.1"
local MINOR_VERSION = 1

if not AceLibrary then error(MAJOR_VERSION.." requires AceLibrary")end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION)then return end
if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION.." requires AceOO-2.0")end
if not AceLibrary:HasInstance("AceEvent-2.0") then error(MAJOR_VERSION.." requires AceEvent-2.0")end
if not AceLibrary:HasInstance("AceLocale-2.2") then error(MAJOR_VERSION.." requires AceLocale-2.2")end

-- Addon frames
local BHC = CreateFrame("Frame")
BHC.tooltip = CreateFrame("GameTooltip", "BHCTooltip", nil, "GameTooltipTemplate")
BHC.tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Locale
local L = AceLibrary("AceLocale-2.2"):new("BetterHealComm-0.1")

-- Player name/class
local name = UnitName("player")
local _, class = UnitClass("player")

-- Function aliases
local insert = table.insert
local remove = table.remove
local concat = table.concat
local getn = table.getn
local find = string.find
local bitand = bit.band

-- Spell bitmasks
local DAMAGE = 0
local HEAL   = 1
local OT     = 2
local AOE    = 4
local RES    = 8

-- Group tokens
local RAID = 2
local PARTY = 1
local NONE = 0

-- ----------------------------------------------------------------------------
-- Utility functions
-- ----------------------------------------------------------------------------
local table_setn
do
    local version = GetBuildInfo()
    if string.find(version, "^2%.") then
        -- 2.0.0
        table_setn = function() end
    else
        table_setn = table.setn
    end
end

local tmp
local function print(a,b,c,d,e,f,g,h,i,j,k,l,n,o,p,q,r,s,t)
    tmp = tmp or {}
    insert(tmp, a) insert(tmp, b) insert(tmp, c) insert(tmp, d) insert(tmp, e)
    insert(tmp, f) insert(tmp, g) insert(tmp, h) insert(tmp, i) insert(tmp, j)
    insert(tmp, k) insert(tmp, l) insert(tmp, m) insert(tmp, n) insert(tmp, o)
    insert(tmp, p) insert(tmp, q) insert(tmp, r) insert(tmp, s) insert(tmp, t)
    while tmp[getn(tmp)] == nil do
        remove(tmp)
    end
    for i=1,getn(tmp) do
        tmp[i] = tostring(tmp[i])
    end
    if find(tostring(a), "%%") then
        DEFAULT_CHAT_FRAME:AddMessage("|cff77ff77[BHC]|r "..format(remove(tmp,1),unpack(tmp)))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff77ff77[BHC]|r "..concat(tmp," "))
    end
    table_setn(tmp, 0)
end

-- https://en.wikipedia.org/wiki/HSL_and_HSV
-- @param h Hue (0-360)
-- @param s Saturation (0-1)
-- @param l Lightness (0-1)
local function HSV(h, s, l)
    h, s, l = mod(abs(h), 360) / 60, abs(s), abs(l)
    if s > 1 then s = mod(s, 1) end
    if l > 1 then l = mod(l, 1) end
    local c = (1 - abs(2 * l - 1)) * s
    local x = c * (1 - abs(mod(h, 2) - 1))
    local r, g, b
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    local m = l - c / 2
    return r + m, g + m, b + m
end

-- @param unitID Unit identifier string
-- @return true if unitID is visible and connected, else false
-- @return true if unitID is assistable, else false
local function UnitIsValidAssist(unitID)
    return UnitIsVisible(unitID) ~= nil and UnitIsConnected(unitID) and
    1 == UnitCanAssist("player", unitID)
end

function strsplit(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = strfind(str, fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = strfind(str, fpat, last_end)
    end
    if last_end <= strlen(str) then
        cap = strsub(str, last_end)
        table.insert(t, cap)
    end
    return t
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
-- Stats
-- ----------------------------------------------------------------------------

local spirit = 0
local healing = 0

function BHC:UpdateStats()
    _, spirit = UnitStat("player", 5)
    if BonusScanner then
        healing = BonusScanner:GetBonus("HEAL")
    else
        healing = 0
    end
end

-- ----------------------------------------------------------------------------
-- Talents
-- ----------------------------------------------------------------------------

-- Priest
local irMod = 0 -- Improved Renew
local sgMod = 0 -- Spiritual Guidance
local shMod = 0 -- Spiritual Healing

function BHC:UpdateTalents()
    -- Improved Renew
    local _,_,_,_,irRank = GetTalentInfo(2, 2)
    irMod = 5*irRank/100+1
    -- Spiritual Guidance
    local _,_,_,_,sgRank = GetTalentInfo(2, 14)
    sgMod = 5*sgRank/100
    -- Spiritual Healing
    local _,_,_,_,shRank = GetTalentInfo(2, 15)
    shMod = 2*shRank/100+1
end

-- ----------------------------------------------------------------------------
-- Spells
-- ----------------------------------------------------------------------------

-- Spell codes
-- is aoe-heal?: `bitand(spell.type, HEAL+AOE) == HEAL+AOE`
--            or `spell.type == HEAL+AOE` (since no masks larger than AOE,
--                                          discounting res)
-- is heal?: `bitand(spell.type, HEAL) == HEAL`
-- is DoT?: `bitand(spell.type, DAMAGE+OT) == DAMAGE+OT`
--
-- Note: Blizzard spell tooltips account for direct increases to base values
-- from talents!
-- e.g. Greater Heal (Rank 1) without Spritual Healing: 899
--      Greater heal (Rank 1) WITH 5/5 Spiritual Healing: 988 (899 * 1.10)
--
-- Spell efficiency is equal to "spell-percent * rank-percent" unless the spell
-- level is under 20, in which "rank-percent = rank-percent * 0.0375 *
-- level-rank-learned + 0.25".

local spells = {
    -- Druid
    [L["Healing Touch"]] = {
        type = HEAL,
        [1]  = function(spellPower)
            return shMod*45+1.5 / 3.5 * (0.0375 * 1  + 0.25)*(spellPower+sgMod*spirit)
        end,
        [2]  = function(spellPower)
            return shMod*101+2   / 3.5 * (0.0375 * 8  + 0.25)*(spellPower+sgMod*spirit)
        end,
        [3]  = function(spellPower)
            return shMod*220+2.5 / 3.5 * (0.0375 * 14 + 0.25)*(spellPower+sgMod*spirit)
        end,
        [4]  = function(spellPower)
            return shMod*405+1*(spellPower+sgMod*spirit)
        end,
        [5]  = function(spellPower)
            return shMod*634+1*(spellPower+sgMod*spirit)
        end,
        [6]  = function(spellPower)
            return shMod*819+1*(spellPower+sgMod*spirit)
        end,
        [7]  = function(spellPower)
            return shMod*1029+1*(spellPower+sgMod*spirit)
        end,
        [8]  = function(spellPower)
            return shMod*1314+1*(spellPower+sgMod*spirit)
        end,
        [9]  = function(spellPower)
            return shMod*1657+1*(spellPower+sgMod*spirit)
        end,
        [10] = function(spellPower)
            return shMod*2061+1*(spellPower+sgMod*spirit)
        end,
        [11] = function(spellPower)
            return shMod*2473+1*(spellPower+sgMod*spirit)
        end
    },
    [L["Regrowth"]] = {
        type = HEAL+OT,
        -- Not account for HoT component yet!
        [1] = function(spellPower)
            return shMod*92+0.325 * (0.0375 * 12 + 0.25)*(spellPower+sgMod*spirit)
        end,
        [2] = function(spellPower)
            return shMod*177+0.325 * (0.0375 * 18 + 0.25)*(spellPower+sgMod*spirit)
        end,
        [3] = function(spellPower)
            return shMod*258+0.325*(spellPower+sgMod*spirit)
        end,
        [4] = function(spellPower)
            return shMod*340+0.325*(spellPower+sgMod*spirit)
        end,
        [5] = function(spellPower)
            return shMod*432+0.325*(spellPower+sgMod*spirit)
        end,
        [6] = function(spellPower)
            return shMod*564+0.325*(spellPower+sgMod*spirit)
        end,
        [7] = function(spellPower)
            return shMod*686+0.325*(spellPower+sgMod*spirit)
        end,
        [8] = function(spellPower)
            return shMod*858+0.325*(spellPower+sgMod*spirit)
        end,
        [9] = function(spellPower)
            return shMod*1062+0.325*(spellPower+sgMod*spirit)
        end
    },
    [L["Rejuvenation"]] = {
        type = OT,
        hotInterval = 3,
        [1]  = function(spellPower)
            return shMod*32+0.8 * (0.0375 *  4 + 0.25)*(spellPower+sgMod*spirit)
        end,
        [2]  = function(spellPower)
            return shMod*56+0.8 * (0.0375 * 10 + 0.25)*(spellPower+sgMod*spirit)
        end,
        [3]  = function(spellPower)
            return shMod*116+0.8 * (0.0375 * 16 + 0.25)*(spellPower+sgMod*spirit)
        end,
        [4]  = function(spellPower)
            return shMod*180+0.8*(spellPower+sgMod*spirit)
        end,
        [5]  = function(spellPower)
            return shMod*244+0.8*(spellPower+sgMod*spirit)
        end,
        [6]  = function(spellPower)
            return shMod*304+0.8*(spellPower+sgMod*spirit)
        end,
        [7]  = function(spellPower)
            return shMod*388+0.8*(spellPower+sgMod*spirit)
        end,
        [8]  = function(spellPower)
            return shMod*488+0.8*(spellPower+sgMod*spirit)
        end,
        [9]  = function(spellPower)
            return shMod*608+0.8*(spellPower+sgMod*spirit)
        end,
        [10] = function(spellPower)
            return shMod*756+0.8*(spellPower+sgMod*spirit)
        end,
        [11] = function(spellPower)
            return shMod*888+0.8*(spellPower+sgMod*spirit)
        end
    },
    [L["Resurrection"]] = {
        type = RES
    },
    [L["Lesser Heal"]] = {
        type = HEAL,
        [1] = function(spellPower)
            return 57+(2.1/3.5)*(2.51/3.5)*(0.0375*1+0.25)*(spellPower+sgMod*spirit)
        end,
        [2] = function(spellPower)
            return 86+(2.9/3.5)*(2.51/3.5)*(0.0375*4+0.25)*(spellPower+sgMod*spirit)
        end,
        [3] = function(spellPower)
            return 158+(2.51/3.5)*(0.0375*10+0.25)*(spellPower+sgMod*spirit)
        end
    },
    [L["Heal"]] = {
        type = HEAL,
        [1] = function(spellPower)
            return shMod*319+3 / 3.5 * (0.0375 * 16 + 0.25)*(spellPower+sgMod*spirit)
        end,
        [2] = function(spellPower)
            return shMod*471+3 / 3.5*(spellPower+sgMod*spirit)
        end,
        [3] = function(spellPower)
            return shMod*610+3 / 3.5*(spellPower+sgMod*spirit)
        end,
        [4] = function(spellPower)
            return shMod*759+3 / 3.5*(spellPower+sgMod*spirit)
        end
    },
    [L["Greater Heal"]] = {
        type = HEAL,
        [1] = function(spellPower)
            return shMod*957+3 / 3.5*(spellPower+sgMod*spirit)
        end,
        [2] = function(spellPower)
            return shMod*1220+3 / 3.5*(spellPower+sgMod*spirit)
        end,
        [3] = function(spellPower)
            return shMod*1524+3 / 3.5*(spellPower+sgMod*spirit)
        end,
        [4] = function(spellPower)
            return shMod*1903+3 / 3.5*(spellPower+sgMod*spirit)
        end,
        [5] = function(spellPower)
            return shMod*2081+3 / 3.5*(spellPower+sgMod*spirit)
        end,
    },
    [L["Flash Heal"]] = {
        type = HEAL,
        [1] = function(spellPower)
            return shMod*212+1.5/3.5*(spellPower+sgMod*spirit)
        end,
        [2] = function(spellPower)
            return shMod*287+1.5 / 3.5*(spellPower+sgMod*spirit)
        end,
        [3] = function(spellPower)
            return shMod*361+1.5 / 3.5*(spellPower+sgMod*spirit)
        end,
        [4] = function(spellPower)
            return shMod*440+1.5 / 3.5*(spellPower+sgMod*spirit)
        end,
        [5] = function(spellPower)
            return shMod*568+1.5 / 3.5*(spellPower+sgMod*spirit)
        end,
        [6] = function(spellPower)
            return shMod*705+1.5 / 3.5*(spellPower+sgMod*spirit)
        end,
        [7] = function(spellPower)
            return shMod*886+1.5 / 3.5*(spellPower+sgMod*spirit)
        end
    },
    [L["Prayer of Healing"]] = {
        type = HEAL+AOE,
        [1] = function(spellPower)
            return shMod*312+3/3.5/3*(spellPower+sgMod*spirit)
        end,
        [2] = function(spellPower)
            return shMod*459+3/3.5/3*(spellPower+sgMod*spirit)
        end,
        [3] = function(spellPower)
            return shMod*677+3/3.5/3*(spellPower+sgMod*spirit)
        end,
        [4] = function(spellPower)
            return shMod*966+3/3.5/3*(spellPower+sgMod*spirit)
        end,
        [5] = function(spellPower)
            return shMod*1071+3/3.5/3*(spellPower+sgMod*spirit)
        end
    },
    [L["Renew"]] = {
        type = HEAL+OT,
        [1]  = function(spellPower)
            return shMod*irMod*45+0.55*(spellPower+sgMod*spirit)
        end,
        [2]  = function(spellPower)
            return shMod*irMod*100+0.775*(spellPower+sgMod*spirit)
        end,
        [3]  = function(spellPower)
            return shMod*irMod*175+(spellPower+sgMod*spirit)
        end,
        [4]  = function(spellPower)
            return shMod*irMod*245+(spellPower+sgMod*spirit)
        end,
        [5]  = function(spellPower)
            return shMod*irMod*315+(spellPower+sgMod*spirit)
        end,
        [6]  = function(spellPower)
            return shMod*irMod*400+(spellPower+sgMod*spirit)
        end,
        [7]  = function(spellPower)
            return shMod*irMod*510+(spellPower+sgMod*spirit)
        end,
        [8]  = function(spellPower)
            return shMod*irMod*650+(spellPower+sgMod*spirit)
        end,
        [9]  = function(spellPower)
            return shMod*irMod*810+(spellPower+sgMod*spirit)
        end,
        [10] = function(spellPower)
            return shMod*irMod*970+(spellPower+sgMod*spirit)
        end
    }
}

-- ----------------------------------------------------------------------------
-- Ranks
-- ----------------------------------------------------------------------------

local knownRank = {}
for k,_ in pairs(spells) do
    knownRank[k] = 0
end

function BHC:UpdateKnownRanks()
    local i, spell, rank = 1, GetSpellName(1, "spell")
    while spell do
        if spells[spell] then
            _,_,rank = find(rank, L["Rank (%d+)"])
            knownRank[spell] = tonumber(rank)
        end
        i = i + 1
        spell, rank = GetSpellName(i, "spell")
    end
end

-- ----------------------------------------------------------------------------
-- Current spell
-- ----------------------------------------------------------------------------

local current = {
    spell = false,
    rank = false,
    type = false,
    amount = false,
    target = false,
    targetName = false,
}

function BHC:SetCurrentSpell(spell, rank, target)
    if current.isCasting then
        return
    end
    if spell == nil then spell = current.spell end
    if rank == nil then rank = current.rank end
    if target == nil then target = current.target end

    current.spell = spell
    current.rank = rank
    if spells[spell] then
        current.type = spells[spell].type
        if spells[spell][rank] then
            current.amount = floor(spells[spell][rank](healing))
        end
    else
        current.type = false
        current.amount = false
    end
    current.target = target
    current.targetName = target and UnitName(current.target)
    --self:PrintCurrentSpell()
end

function BHC:GetCurrentSpell()
    return current.spell, current.rank,
    current.target,current.targetName,
    current.amount
end

function BHC:PrintCurrentSpell(prefix)
    local s, h, r, g, b = "", 0
    for k,v in pairs(current) do
        r, g, b = HSV(h, 1, 0.5)
        s=s..format(" |cff%02x%02x%02x%s|r:%q", r*255, g*255, b*255, k, tostring(v))
        h = h + 45
    end
    print((prefix or "")..s)
end

-- ----------------------------------------------------------------------------
-- Event handlers
-- ----------------------------------------------------------------------------

-- CURRENT_SPELL_CAST_CHANGED

function BHC:AceEvent_FullyInitialized()
    self:TriggerEvent("BetterHealComm_Enabled")

    self:RegisterEvent("SPELLCAST_START", "OnSpellCast")
    self:RegisterEvent("SPELLCAST_INTERRUPTED", "OnSpellCast")
    self:RegisterEvent("SPELLCAST_FAILED", "OnSpellCast")
    self:RegisterEvent("SPELLCAST_DELAYED", "OnSpellCast")
    self:RegisterEvent("SPELLCAST_STOP", "OnSpellCast")

    self:RegisterEvent("CHAT_MSG_ADDON", "OnRecieve")

    self:UpdateTalents()
    self:UpdateStats()
    self:UpdateKnownRanks()

    self:HookWoWAPI()
end

function BHC:OnSpellCast(...)
    if event == "SPELLCAST_START" then
        if current.spell then
            if not current.isCasting then
                self:Send(true)
                current.isCasting = true
            end
        end
    elseif event == "SPELLCAST_INTERRUPTED" or
        event == "SPELLCAST_FAILED" then
        if current.spell then
            if current.isCasting then
                self:Send(false)
                current.isCasting = false
                self:SetCurrentSpell(false, false, false)
            end
        end
    elseif event == "SPELLCAST_STOP" then
        if current.spell then
            if bitand(current.type, OT) == OT then
                self:Send(true)
                self:SetCurrentSpell(false, false, false)
            elseif current.isCasting then
                self:Send(false)
                current.isCasting = false
                self:SetCurrentSpell(false, false, false)
            end
        end
    elseif event == "SPELLCAST_DELAYED" then
        local msDelay = arg[1]
    end
    --print(format("|cffff77ff[%s]|r",event),unpack(arg))
    --self:PrintCurrentSpell("|cff7777ff[OnSpellCast]|r")
end

-- ----------------------------------------------------------------------------
-- Messaging
-- ----------------------------------------------------------------------------
-- current { name, rank, type, target, targetName, amount }
-- S/playerName/targetName/type/amount

function BHC:Send(isStart)
    --print("|cff7777ff[Send]|r", name, current.targetName, current.type, current.amount)
    -- Send addon message
    SendAddonMessage("BetterHealComm", format("%s/%s/%s/%s/%s", isStart and "S"
    or "s", name, (current.targetName or ""), current.type, current.amount),
    "RAID")
    -- Send local trigger
    self:TriggerEvent("BetterHealComm_"..(isStart and "Start" or "Stop"), name,
    current.targetName, current.type, current.amount)
end

function BHC:OnRecieve(addon, msg)
    if addon == "BetterHealComm" then
        --print("|cffff7777[OnRecieve]|", msg)
        local token, from, to, type, amount = unpack(strsplit(msg, "/"))
        if from == name then
            return
        end
        if token == "S" then
            self:TriggerEvent("BetterHealComm_Start", from, to, type, amount)
        else
            self:TriggerEvent("BetterHealComm_Stop", from, to, type, amount)
        end
    end
end

-- ----------------------------------------------------------------------------
-- Hook WoW API functions
-- ----------------------------------------------------------------------------
-- Only called for healing classes.
--
-- Hook functions that involve spells in targeting to pull information from:
-- CastSpell, CastSpellByName, SpellTargetUnit, SpellStopTargeting
-- TargetUnit, UseAction, WorldFrame:OnMouseDown

function BHC:HookWoWAPI()
    -- CastSpell
    -- @param id Spell index in spellbook
    -- @param bookType "spell" or "pet"
    local OldCastSpell = CastSpell
    local function NewCastSpell(id, bookType)
        OldCastSpell(id, bookType) -- Call old
        local spell, rank = GetSpellName(id, bookType)
        if not (spell and spells[spell]) then
            -- Not a spell we care about
            return
        end
        _,_,rank = find(rank, L["Rank (%d+)"])
        rank = tonumber(rank) or knownRank[spell]
        self:SetCurrentSpell(spell, rank, SpellIsTargeting() ~= 1 and "target")
    end
    CastSpell = NewCastSpell

    -- CastSpellByName
    -- @param spell Localized spell spell
    -- @param target Target or nil
    local OldCastSpellByName = CastSpellByName
    local function NewCastSpellByName(spell, onSelf)
        OldCastSpellByName(spell, onSelf) -- Call old
        local _,_,rank = find(spell, L["Rank (%d+)"])
        local _,_,spell = find(spell, L["([%w%s:]+)"])
        if not spells[spell] then
            -- Not a spell we care about
            return
        end
        rank = tonumber(rank) or knownRank[spell]
        if not (rank <= knownRank[spell]) then
            -- Not a known rank
            return
        end
        self:SetCurrentSpell(spell, rank, onSelf and "player" or UnitIsValidAssist("target") and "target")
    end
    CastSpellByName = NewCastSpellByName

    -- SpellTargetUnit
    -- @param unit UnitID to target with spell on cursor
    local OldSpellTargetUnit = SpellTargetUnit
    local function NewSpellTargetUnit(unit)
        if SpellIsTargeting() then
            self:SetCurrentSpell(nil, nil, unit)
        end
        OldSpellTargetUnit(unit) -- Call old
    end
    SpellTargetUnit = NewSpellTargetUnit

    -- SpellStopTargeting
    local OldSpellStopTargeting = SpellStopTargeting
    local function NewSpellStopTargeting()
        OldSpellStopTargeting() -- Call old
        self:SetCurrentSpell(false, false, false)
    end
    SpellStopTargeting = NewSpellStopTargeting

    -- TargetUnit
    -- @param unit UnitID to target
    local OldTargetUnit = TargetUnit
    local function NewTargetUnit(unit)
        if SpellIsTargeting() then
            self:SetCurrentSpell(nil, nil, unit)
        end
        OldTargetUnit(unit)
    end
    TargetUnit = NewTargetUnit

    -- UseAction
    -- @param slot
    -- @param checkCursor
    -- @param onSelf
    local OldUseAction = UseAction
    local function NewUseAction(slot, checkCursor, onSelf)
        OldUseAction(slot, checkCursor, onSelf) -- Call old
        if GetActionText(slot) then
            -- Is a macro
            return
        end
        self.tooltip:ClearLines()
        self.tooltip:SetAction(slot)
        local spell = BHCTooltipTextLeft1:GetText()
        if not spells[spell] then
            -- Isn't a spell we care about
            return
        end
        local rank = BHCTooltipTextRight1:GetText()
        _,_,rank = find(rank, L["Rank (%d+)"])
        local target = onSelf and "player" or UnitIsValidAssist("target") and "target"
        self:SetCurrentSpell(spell, tonumber(rank), target)
    end
    UseAction = NewUseAction

    -- WorldFrame:OnMouseDown
    local OldOnMouseDown = WorldFrame:GetScript("OnMouseDown")
    local function NewOnMouseDown()
        OldOnMouseDown() -- Call old
        if not GameTooltipTextLeft1:IsVisible() then
            return
        end
        local _,_,targetName = find(GameTooltipTextLeft1:GetText(), L["^Corpse of (%w+)$"])
        if UnitIsValidAssist("mouseover") or targetName then
            self:SetCurrentSpell(nil, nil, "mouseover")
        end
    end
    WorldFrame:SetScript("OnMouseDown", NewOnMouseDown)
end

-- ----------------------------------------------------------------------------
-- API
-- ----------------------------------------------------------------------------

AceLibrary:Register(BHC, MAJOR_VERSION, MINOR_VERSION, activate, deactivate, external)
