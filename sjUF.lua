-- TODO:
-- Add party and other frames
-- Add power bars of all types to allow showing multiple (if say it's a druid)
-- Repair FuBar loading (reference BugSackFu)
-- Better chain of and separation in updating layout and unit data

-- sjUF.frames.player
-- sjUF.frames.target
-- sjUF.frames.targetstarget
-- sjUF.frames.targetstargetstarget
-- sjUF.frames.pet
-- sjUF.frames.raid.raid1-40 (double as party1-5)
-- raid1-5 double as party1-5
-- raid1 doubles as player

local m_event = "|cffff77ff[EVENT]|r "
local m_raid  = "|cff7777ff[RAID]|r "

local function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Create addon module
sjUF = AceLibrary("AceAddon-2.0"):new(
"AceConsole-2.0",
"AceDebug-2.0",
"AceDB-2.0",
"AceEvent-2.0",
"FuBarPlugin-2.0")

-- RosterLib
local RL = AceLibrary("RosterLib-2.0")

--[[
[function strsplit(str, pat)
[    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
[    local fpat = "(.-)" .. pat
[    local last_end = 1
[    local s, e, cap = strfind(str, fpat, 1)
[    while s do
[        if s ~= 1 or cap ~= "" then
[            table.insert(t,cap)
[        end
[        last_end = e+1
[        s, e, cap = strfind(str, fpat, last_end)
[    end
[    if last_end <= strlen(str) then
[        cap = strsub(str, last_end)
[        table.insert(t, cap)
[    end
[    return t
[end
]]

-- @param a Original
-- @param b Table to fill
local function TableCopy(a, b)
    for k,v in pairs(a) do
        if (type(v) == "table") then
            Copy(a[k], b[k])
        else
            b[k] = a[k]
        end
    end
end

-- @param table Table to print
-- @param indentLevel Indent level for recursion (leave nil)
local function TablePrint(table, indentLevel)
    indentLevel = indentLevel or 0
    local indent = ""
    for i = 1, indentLevel do
        indent = indent..".. "
    end
    for k,v in pairs(table) do
        if type(v) ~= "table" then
            sjUF:Print(indent..string.format(
            "[%s] (%s) = %s", tostring(k), type(v), tostring(v)))
        else
            sjUF:Print(indent..string.format(
            "[%s] (table) =", tostring(k)))
            TablePrint(v, indentLevel + 1)
        end
    end
end

-- Frame references
local master, player, pet, target, tot, totot, raid

local options = {
    type = "group",
    args = {
        raid_enable = {
            order = 1,
            name = "Raid enable",
            desc = "Toggle raid frame enable.",
            type = "toggle",
            get = function()
                return sjUF.opt.raid_enable
            end,
            set = function(set)
                sjUF.opt.raid_enable = set
                if set then
                    sjUF.raid:Show()
                else
                    sjUF.raid:Hide()
                end
            end
        },
        raid_lock = {
            order = 2,
            name = "Raid lock",
            desc = "Toggle raid frame lock.",
            type = "toggle",
            get = function()
                return sjUF.opt.raid_lock
            end,
            set = function(set)
                sjUF.opt.raid_lock = set
                sjUF.raid:Lock(set)
            end
        },
        raid_reset = {
            order = 3,
            name = "Raid reset",
            desc = "Reset raid position.",
            type = "execute",
            func = function()
                sjUF.raid:ClearAllPoints()
                sjUF.raid:SetPoint("CENTER", UIParent, "CENTER")
            end
        },
        raid_dummy_frames = {
            order = 4,
            name = "Raid dummy frames",
            desc = "Toggle showing dummy raid unit frames.",
            type = "toggle",
            get = function()
                return sjUF.opt.raid_dummy_frames
            end,
            set = function(set)
                sjUF.opt.raid_dummy_frames = set
                sjUF:UpdateRaidFramePositions()
            end
        },
        raid_alt_layout = {
            order = 5,
            name = "Raid alt layout",
            desc = "Toggle using the 25 man raid layout.",
            type = "toggle",
            get = function()
                return sjUF.opt.raid_alt_layout
            end,
            set = function(set)
                sjUF.opt.raid_alt_layout = set
                sjUF:UpdateRaidFrames()
            end,
            map = { [false] = "40 man", [true] = "25 man" }
        },
        raid_width = {
            order = 6,
            name = "Raid unit width",
            desc = "Set width of raid unit frames.",
            type = "range",
            min = 0,
            max = 600,
            step = 5,
            bigStep = 20,
            get = function()
                return sjUF.opt.raid_width
            end,
            set = function(set)
                if sjUF.opt.raid_width ~= set then
                    sjUF.opt.raid_width = set
                    sjUF:UpdateRaidFrames()
                end
            end
        },
        raid_height = {
            order = 7,
            name = "Raid unit height",
            desc = "Set height of raid unit frames.",
            type = "range",
            min = 0,
            max = 600,
            step = 5,
            bigStep = 20,
            get = function()
                return sjUF.opt.raid_height
            end,
            set = function(set)
                if sjUF.opt.raid_height ~= set then
                    sjUF.opt.raid_height = set
                    sjUF:UpdateRaidFrames()
                end
            end
        }
    }
}

local defaults = {
    raid_enable = true,
    raid_lock = true,
    raid_dummy_frames = false,
    raid_alt_layout = false, -- false=40, true=25
    raid_width = 320,
    raid_height = 200
}

function sjUF:OnInitialize()
    -- AceConsole
    self:RegisterChatCommand({"/sjUnitFrames", "/sjUF"}, options)
    -- AceDB
    self:RegisterDB("sjUF_DB")
    self:RegisterDefaults("profile", defaults)
    self.opt = self.db.profile
    -- AceDebug
    self:SetDebugging(sjUF.opt.debugging)
    -- FuBar plugin
    self.defaultMinimapPosition = 270
    self.cannotDetachTooltip = true
    self.OnMenuRequest = options
    self.hasIcon = true
    self:SetIcon("Interface\\Icons\\Spell_Holy_PowerInfusion")
    -- Initialize frames
    sjUF:InitFrames()
end

function sjUF:OnEnable()
    self:Debug(m_event.."OnEnable")
    -- Events
    self:RegisterEvent("RosterLib_RosterChanged", "OnRosterChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    self:RegisterEvent("UNIT_AURA", "OnUnitAura")
    --
    self:CheckGroupStatus()
    self:UpdateRaidFrames()
end

function sjUF:OnDisable()
    self:Debug(m_event.."OnDisable")
    self.raid:Hide()
end

function sjUF:SetDebugging(set)
    self.opt.debugging = set
    self.debugging = set
end

function sjUF:OnRosterChanged(table)
    self:Debug(m_event.."OnRosterChanged")
    if self.group_status ~= self:CheckGroupStatus() then
        self:UpdateRaidFrames()
    end
end

function sjUF:OnPlayerEnteringWorld()
    sjUF:Debug(m_event.."OnPlayerEnteringWorld")
    if sjUF.group_status ~= sjUF:CheckGroupStatus() then
        sjUF:UpdateRaidFrames()
    end
end

function sjUF:OnUnitAura(unitID)
end

--- Updates and returns player group status.
-- @return 0 = no group, 1 = party, 2 = raid
function sjUF:CheckGroupStatus()
    self.group_status = UnitInRaid("player") and 2 or UnitExists("party1") and 1 or 0
    return self.group_status
end

function sjUF:InitFrames()
    -- ------------------------------------------------------------------------
    -- RAID
    -- ------------------------------------------------------------------------
    -- Container
    self.raid = self.raid or CreateFrame("Frame", "sjUF_Raid", UIParent)
    raid = self.raid
    raid:SetClampedToScreen(true)
    raid:SetMovable(true)
    raid.anchor = raid.anchor or CreateFrame("Frame", "sjUF_RaidAnchor", raid)
    raid.anchor:SetParent(raid)
    raid.anchor:SetPoint("TOPLEFT", -5, 5)
    raid.anchor:SetPoint("BOTTOMRIGHT", 5, -5)
    raid.anchor.background = raid.anchor.background or raid.anchor:CreateTexture(nil, "BACKGROUND")
    raid.anchor.background:SetTexture(0.5, 0.5, 0.5, 0.5)
    raid.anchor.background:SetAllPoints()
    raid.anchor:RegisterForDrag("LeftButton")
    raid.anchor:SetScript("OnDragStart", function()
        raid:StartMoving()
    end)
    raid.anchor:SetScript("OnDragStop", function()
        raid:StopMovingOrSizing()
    end)
    function raid:Lock(enable)
        if enable == nil then
            enable = not slUF.opt.raid_lock
        end
        sjUF.opt.raid_lock = enable
        self.anchor:EnableMouse(not enable)
        if enable then
            self.anchor:Hide()
        else
            self.anchor:Show()
        end
    end
    raid:Lock(self.opt.raid_lock)
    -- Unit frames
    self.raid_units = self.raid_units or {}
    for i = 1, 40 do
        self.raid_units[i] = self.raid_units[i] or CreateFrame("Button", "sjUF_Raid"..i, raid)
        local f = self.raid_units[i]
        f:SetID(i)
        f.background = f:CreateTexture(nil, "BACKGROUND")
        f.background:SetTexture(random(), random(), random(), 0.75)
        f.background:SetAllPoints()
        f.name = f:CreateFontString("sjUF_Raid"..i.."Name")
        f.name:SetFontObject(GameFontDarkGraySmall)
        f.name:SetText("Raid"..i)
        f.hp_bar = CreateFrame("StatusBar", "sjUF_Raid"..i.."Health", f)
        f.hp_bar:SetMinMaxValues(0, 100)
        f.hp_bar:SetFrameLevel(2)
        f.mp_bar = CreateFrame("StatusBar", "sjUF_Raid"..i.."Energy", f)
        f.mp_bar:SetMinMaxValues(0, 100)
        f.mp_bar:SetFrameLevel(2)
    end

    sjUF:UpdateRaidFrames()
end

--- Update raid frames.
function sjUF:UpdateRaidFrames()
    self:UpdateRaidFramePositions()
    self:UpdateRaidFrameStyles()
    self:UpdateRaidFrameUnits()
end

function sjUF:UpdateRaidFramePositions()
    local group_status = self.opt.raid_dummy_frames and 2 or self.group_status
    -- Container
    self.raid:SetWidth(self.opt.raid_width)
    self.raid:SetHeight(self.opt.raid_height)
    -- Units
    local units_per_row = group_status == 2 and not self.opt.raid_alt_layout and 8 or 5
    local units_per_column = 5
    local unit_width = self.opt.raid_width / units_per_row
    local unit_height = self.opt.raid_height / units_per_column
    for i=1,40 do
        local f = self.raid_units[i]
        if not self.opt.raid_alt_layout or i <= 25 then
            local x = mod(i-1, units_per_row)
            local y = floor((i-1)/units_per_row)
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", x*unit_width, -y*unit_height)
            f:SetWidth(unit_width)
            f:SetHeight(unit_height)
            f:Show()
        else
            f:Hide()
        end
    end
    --for r = 0, units_per_column-1 do
        --for c = 0, units_per_row-1 do
            --local f = self.raid_units[r*units_per_row + c+1]
            --f:ClearAllPoints()
            --f:SetPoint("TOPLEFT", c*unit_width, -r*unit_height)
            --f:SetWidth(unit_width)
            --f:SetHeight(unit_height)
        --end
    --end
end

function sjUF:UpdateRaidFrameStyles()
end

function sjUF:UpdateRaidFrameUnits()
    for i=1, 40 do
    end
end

--- Set frame width, height and point.
--[[
[local function FrameSetWHP(f, width, height, point, relativeTo, relativePoint, xOffset, yOffset)
[    f:SetWidth(width)
[    f:SetHeight(height)
[    if point then
[        f:ClearAllPoints()
[        f:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
[    end
[end
]]

--[[
[local function UnitFrameSetHighlight(unitFrame, enable)
[    assert(type(enable) == "boolean")
[    if enable then
[        unitFrame.highlight:Show()
[    else
[        unitFrame.highlight:Hide()
[    end
[end
]]

--[[
-- Unit frame styling
-- frame_width (float)
-- frame_height (float)
-- hp_bar_height_weight (int)
-- mp_bar_enable (boolean)
-- mp_bar_height_weight (int)
--]]
--[[
-- Unit data styling
-- hp_bar_class_color
--]]

-- Set unit independent properties here.
-- No class colors, unit names, etc.
--[[
[local function UnitFrameSetStyle(unit_frame, style)
[    assert(type(style) == "table")
[    -- Frame dimensions
[    unit_frame:SetWidth(style.frame_width)
[    unit_frame:SetHeight(style.frame_height)
[    -- Status bars
[    local hp_bar_scale, mp_bar_scale
[    if style.mp_bar_enable then
[        hp_bar_scale = style.hp_bar_height_weight /
[        (style.hp_bar_scale_weight + style.mp_bar_scale_weight)
[        mp_bar_scale = 1 - hp_bar_scale
[    else
[        hp_bar_scale, mp_bar_scale = 1.0, 0.0
[    end
[end
]]

--- Create unit frame.
--[[
[function sjUF:CreateUnitFrame(frame)
[    --local domain = gsub(unitID, "%d*", '')
[    --local index  = gsub(unitID, "%D*", '')
[    --local f = CreateFrame("Button", nil, sjUF.master)
[
[    -- TODO:
[    -- Buff/debuff bar instead of set number of frames
[
[    f.backdrop = CreateFrame("Frame", nil, f)
[    f.backdrop:SetFrameLevel(1)
[
[    f.name = f:CreateFontString(nil, "ARTWORK")
[
[    f.hp_bar = CreateFrame("StatusBar", nil, f)
[    f.hp_bar:SetMinMaxValues(0, 100)
[    f.hp_bar:SetFrameLevel(2)
[
[    f.mp_bar = CreateFrame("StatusBar", nil, f)
[    f.mp_bar:SetMinMaxValues(0, 100)
[    f.mp_bar:SetFrameLevel(2)
[
[    f.hp_text = f:CreateFontString(nil, "ARTWORK")
[
[    f.mp_text = f:CreateFontString(nil, "ARTWORK")
[
[    f.highlight = f:CreateTexture(nil, "OVERLAY")
[    f.highlight:SetTexture("Interface\\AddOns\\sjUF\\media\\textures\\Highlight")
[    f.highlight:SetAllPoints(f)
[    f.highlight:SetAlpha(0.3)
[    f.highlight:SetBlendMode("ADD")
[    f.highlight:Hide()
[
[    -- Functions
[    f.SetHighlight = UnitFrameSetHighlight
[    f.SetStyle = UnitFrameSetStyle
[
[    f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
[    f:SetScript("OnClick", function()
[        TargetUnit(f.unitID)
[    end)
[    f:SetScript("OnEnter", function()
[        f:SetHighlight(true)
[    end)
[    f:SetScript("OnLeave", function()
[        f:SetHighlight(false)
[    end)
[
[    -- Identifiers
[    f.domain = domain
[    if index ~= '' then
[        f.index = index
[    end
[    f.unitID = unitID
[
[    -- Reference
[    sjUF.frames[unitID] = f
[end
]]

--- Set unit frame style.
-- @param f Unit frame
--[[
[function sjUF:SetUnitFrameStyle(f)
[    local unitID = f.unitID
[    local style = sjUF.opt[f.domain].style
[    local _, class = UnitClass(unitID)
[    local hp_color = sjUF.opt.colors.classes[class] or sjUF.opt.colors.default
[    local mp_color = sjUF.opt.colors.powers[0] -- mana
[
[    -- Frame
[    FrameSetWHP(f, style.frame.width, style.frame.height)
[
[    -- Backdrop
[    FrameSetWHP(f.backdrop,
[    style.frame.width + style.backdrop.edge_inset,
[    style.frame.height + style.backdrop.edge_inset,
[    "CENTER", f, "CENTER")
[    local backdrop = sjUF.units[unitID]:GetBackdrop() or {}
[    if style.backdrop.background_enabled then
[        backdrop.bgFile = style.backdrop.background_texture
[    else
[        backdrop.bgFile = nil
[    end
[    if style.backdrop.edge_enabled then
[        backdrop.edgeFile = style.backdrop.edge_texture
[    else
[        backdrop.edgeFile = nil
[    end
[    backdrop.tile = true
[    backdrop.tileSize = 16
[    backdrop.edgeSize = 16
[    backdrop.insets = backdrop.insets or {}
[    backdrop.insets.left = style.backdrop.background_inset
[    backdrop.insets.right = style.backdrop.background_inset
[    backdrop.insets.top = style.backdrop.background_inset
[    backdrop.insets.bottom = style.backdrop.background_inset
[    f.backdrop:SetBackdrop(backdrop)
[    f.backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
[    if (style.backdrop.background_enabled or
[        style.backdrop.edge_enabled) then
[        f.backdrop:Show()
[    else
[        f.backdrop:Hide()
[    end
[
[    -- Status bar scales
[    local hp_scale, mp_scale
[    if style.mp_bar.enabled then
[        local total = style.hp_bar.height_weight + style.mp_bar.height_weight
[        hp_scale = style.hp_bar.height_weight / total
[        mp_scale = 1 - hp_scale
[    else
[        hp_scale = 1
[        mp_scale = 0
[    end
[
[    -- HP bar
[    FrameSetWHP(f.hp_bar, style.frame.width, style.frame.height*hp_scale,
[    "TOP", f, "TOP")
[    f.hp_bar:SetStatusBarTexture(style.hp_bar.texture)
[    f.hp_bar:SetStatusBarColor(hp_color.r, hp_color.g, hp_color.b)
[
[    -- MP bar
[    FrameSetWHP(f.mp_bar, style.frame.width, style.frame.height*mp_scale,
[    "TOP", f.hp_bar, "BOTTOM")
[    f.mp_bar:SetStatusBarTexture(style.mp_bar.texture)
[    f.mp_bar:SetStatusBarColor(mp_color.r, mp_color.g, mp_color.b)
[    if style.mp_bar.enabled then
[        f.mp_bar:Show()
[    else
[        f.mp_bar:Hide()
[    end
[
[    -- Name text
[    FrameSetWHP(f.name, style.frame.width-2, style.name_text.font_size,
[    "TOPLEFT", f, "TOPLEFT", style.name_text.xoffset, style.name_text.yoffset)
[    f.name:SetFont(style.name_text.font, style.name_text.font_size)
[    f.name:SetJustifyH(style.name_text.hjust)
[    if style.name_text.enabled then
[        f.name:Show()
[    else
[        f.name:Hide()
[    end
[
[    -- HP text
[    FrameSetWHP(f.hp_text, style.frame.width-2, style.hp_text.font_size,
[    "TOPLEFT", f, "TOPLEFT", style.hp_text.xoffset, style.hp_text.yoffset)
[    f.hp_text:SetFont(style.hp_text.font, style.hp_text.font_size)
[    f.hp_text:SetJustifyH(style.hp_text.hjust)
[    if style.hp_text.enabled then
[        f.hp_text:Show()
[    else
[        f.hp_text:Hide()
[    end
[
[    -- MP text
[    FrameSetWHP(f.mp_text, style.frame.width-4, style.mp_text.font_size,
[    "TOPLEFT", f, "TOPLEFT", style.mp_text.xoffset, style.mp_text.yoffset)
[    f.mp_text:SetFont(style.mp_text.font, style.mp_text.font_size)
[    f.mp_text:SetJustifyH(style.mp_text.hjust)
[    if style.mp_text.enabled then
[        f.mp_text:Show()
[    else
[        f.mp_text:Hide()
[    end
[end
]]

--[[
[function sjUF:UpdateUnitInfo(f)
[    local name = UnitName(f.unitID)
[    if name and sjUF.opt[f.domain].style.name_text.short then
[        name = string.sub(unit, 1, sjUF.opt.raid.name_text.short_num_chars)
[    end
[    f.name:SetText(name or f.unitID)
[    f.hp_text:SetText("Health")
[    f.mp_text:SetText("Power")
[end
]]

--- Update raid units.
-- Updates the data of raid units, that is name, health and power values. Does
-- not update raid frame layouts (styling, positioning).
--[[
[function sjUF:UpdateRaidUnits()
[    if sjUF.opt.raid.enabled then
[        for i = 1, MAX_RAID_MEMBERS do
[            sjUF:UpdateUnitInfo(sjUF.units["raid"..i])
[            --local f = sjUF.units["raid"..i]
[            --local unit = UnitName(f.unit) or f.unit
[            --if (sjUF.opt.raid.name_short) then
[            --unit = string.sub(unit, 1, sjUF.opt.raid.name_short_chars)
[            --end
[            --if (sjUF.opt.raid.name_enabled) then
[            --f.name:SetText(unit)
[            --end
[            --if (sjUF.opt.raid.hp_text_enabled) then
[            --f.hp_text:SetText("Health")
[            --end
[            --if (sjUF.opt.raid.mp_text_enabled) then
[            --f.mp_text:SetText("Power")
[            --end
[        end
[    end
[end
]]

