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

local function MakeFrameMovable(frame)
end

-- Frame references
local master, player, pet, target, tot, totot, raid

function sjUF:OnInitialize()
    -- Initialize default and options tables
    self:InitConfigTables()

    -- AceConsole
    self:RegisterChatCommand({"/sjUnitFrames", "/sjUF"}, sjUF.options)

    -- AceDB
    self:RegisterDB("sjUF_DB")
    self:RegisterDefaults("profile", sjUF.defaults)
    sjUF.opt = sjUF.db.profile

    -- AceDebug
    self:SetDebugging(sjUF.opt.debug)

    -- FuBar plugin
    self.defaultMinimapPosition = 270
    self.cannotDetachTooltip = true
    self.OnMenuRequest = sjUF.options
    self.hasIcon = true
    self:SetIcon("Interface\\Icons\\Spell_Holy_PowerInfusion")

    -- Initialize frames
    sjUF:InitFrames()
end

function sjUF:OnEnable()
    sjUF:Debug(m_event.."OnEnable")

    -- Events
    sjUF:RegisterEvent("RosterLib_RosterChanged", "OnRosterChanged")
    sjUF:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    sjUF:RegisterEvent("UNIT_AURA", "OnUnitAura")

    sjUF:CheckGroupStatus()

    sjUF:UpdateRaidFrames()
end

function sjUF:OnDisable()
    sjUF:Debug(m_event.."OnDisable")
    --sjUF.master:Hide()
end

function sjUF:OnRosterChanged(table)
    sjUF:Debug(m_event.."OnRosterChanged")
    if sjUF.group_status ~= sjUF:CheckGroupStatus() then
        sjUF:UpdateFrames()
    end
end

function sjUF:OnPlayerEnteringWorld()
    sjUF:Debug(m_event.."OnPlayerEnteringWorld")
    if sjUF.group_status ~= sjUF:CheckGroupStatus() then
        sjUF:UpdateFrames()
    end
end

function sjUF:OnUnitAura(unitID)
end

--- Checks and updates group status.
-- @return 0 = ungroups, 1 = party, 2 = raid
function sjUF:CheckGroupStatus()
    if UnitInRaid("player") then
        sjUF.group_status = 2
        return 2
    elseif UnitExists("party1") then
        sjUF.group_status = 1
        return 1
    end
    sjUF.group_status = 0
    return 0
end

--- Update frames.
function sjUF:UpdateFrames()
    sjUF:Debug(m_event.."UpdateFrames")
    for k,v in pairs(sjUF.frames) do
        if v.enabled then
            v:UpdateStyle()
        end
    end
end

--- Update raid frames.
function sjUF:UpdateRaidFrames()
    --local group_status = sjUF.group_status
    local group_status = 2

    local container_w = 200
    local container_h = 200
    --local unit_xoff, unit_yoff = 1, 1

    --if group_status == 2 then
    --local raid25 = false
    --if raid25 then
    --else
    --local unit_w = (container_w - 7 * unit_xoff) / 8
    --local unit_h = (container_h - 4 * unit_yoff) / 5

    sjUF.raid:SetWidth(container_w)
    sjUF.raid:SetHeight(container_h)
    --for i = 1, 40 do
    --local f = raid.units[i]
    --f:Show()
    --f:SetWidth(unit_w)
    --f:SetHeight(unit_h)
    --f.hp_bar:SetWidth(unit_w)
    --f.hp_bar:SetHeight(unit_h)
    --f.hp_bar:SetStatusBarTexture("Interface\\AddOns\\sjUF\\media\\textures\\Flat.tga")
    --f:ClearAllPoints()
    --if i == 1 then
    --f:SetPoint("TOPLEFT", raid, "TOPLEFT")
    --else
    --if mod(i-1, 8) == 0 then
    --f:SetPoint("TOP", raid.units[i-8], "BOTTOM", 0, -unit_yoff)
    --else
    --f:SetPoint("LEFT", raid.units[i-1], "RIGHT", unit_xoff, 0)
    --end
    --end
    --end
    --end
    --else
    --local unit_w, unit_h = container_w / 5, container_h / 5
    --for i = 1, 5 do
    --local f = raid.units[i]
    --f:Show()
    --f:SetWidth(unit_w)
    --f:SetHeight(unit_h)
    --f.hp_bar:SetWidth(unit_w)
    --f.hp_bar:SetHeight(unit_h)
    --f.hp_bar:SetStatusBarTexture("Interface\\AddOns\\sjUF\\media\\textures\\Smooth.tga")
    --if i == 1 then
    --f:SetPoint("TOPLEFT", raid, "TOPLEFT")
    --else
    --f:SetPoint("TOPLEFT", raid.units[i-1], "TOPRIGHT")
    --end
    --end
    --for i = 6, 40 do
    --raid.units[i]:Hide()
    --end
    --end
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

--- Update raid frames.
-- Updates raid frame layouts, that is styling and positioning. Does not update
-- unit data (name, health, power).
--[[
[function sjUF:UpdateRaidFrames()
[    if not sjUF.opt.raid.enabled then
[        for i = 1, 40 do
[            sjUF.units["raid"..i]:Hide()
[        end
[    else
[        -- sjUF.master:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
[        --sjUF.master:SetWidth(sjUF.opt.raid.width * sjUF.opt.raid.units_per_row + sjUF.opt.raid.xoffset * (sjUF.opt.raid.units_per_row - 1))
[        -- sjUF.master:SetHeight(20)
[        -- sjUF.master.background:SetAllPoints(sjUF.master)
[
[        -- Update styles
[        for i = 1, MAX_RAID_MEMBERS do
[            sjUF:SetUnitFrameStyle(sjUF.units["raid"..i])
[        end
[
[        -- Update positioning
[        local upr, f, row, mod = sjUF.opt.raid.units_per_row
[        sjUF.units.raid1:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
[        for i = 2, MAX_RAID_MEMBERS do
[            f = sjUF.units["raid"..i]
[            row = floor((i-1) / upr)
[            mod = (i-1) - floor((i-1) / upr) * upr
[
[            if mod == 0 then
[                -- Next row, anchor to frame above
[                f:SetPoint("TOPLEFT", sjUF.units["raid"..(row-1)*upr+1],
[                "BOTTOMLEFT", 0, -sjUF.opt.raid.units_yoffset)
[            else
[                -- Anchor to frame on left
[                f:SetPoint("TOPLEFT", sjUF.units["raid"..i-1],
[                "TOPRIGHT", sjUF.opt.raid.units_xoffset, 0)
[            end
[        end
[    end
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

function sjUF.InitConfigTables()
    sjUF.defaults = {
        debug = true,
        raid_enable = true,
        raid_lock = true,
        raid_unit_sizex = 40,
        raid_unit_sizey = 30
    }

    sjUF.options = {
        type = "group",
        args = {
            raid_reset = {
                name = "Raid Reset",
                desc = "Reset raid position",
                type = "execute",
                func = function()
                    --raid:ClearAllPoints()
                    raid:SetPoint("CENTER", UIParent, "CENTER")
                end
            },
            raid_enable = {
                order = 1,
                name = "Raid Enable",
                desc = "Toggle raid frame enable",
                type = "toggle",
                get = function()
                    return sjUF.opt.raid_enable
                end,
                set = function(set)
                    sjUF:Debug(m_raid.."raid_enable="..tostring(set))
                    sjUF.opt.raid_enable = set
                    if set then
                        raid:Show()
                    else
                        raid:Hide()
                    end
                end
            },
            raid_lock = {
                order = 2,
                name = "Raid Lock",
                desc = "Toggle raid frame lock",
                type = "toggle",
                get = function()
                    return sjUF.opt.raid_lock
                end,
                set = function(set)
                    sjUF.opt.raid_lock
                    sjUF.Raid:Lock(set)
                end
            },
            raid_unit_sizex = {
                order = 3,
                name = "Raid unit width",
                desc = "Set width of raid unit frames",
                type = "range",
                min = 1,
                max = 100,
                step = 1,
                get = function()
                    return sjUF.opt.raid_unit_sizex
                end,
                set = function(set)
                    --sjUF.opt.raid_unit_sizex = set
                    sjUF:UpdateRaidFrames()
                end
            },
            raid_unit_sizey = {
                order = 4,
                name = "Raid unit height",
                desc = "Set height of raid unit frames",
                type = "range",
                min = 1,
                max = 100,
                step = 1,
                get = function()
                    return sjUF.opt.raid_unit_sizey
                end,
                set = function(set)
                    --sjUF.opt.raid_unit_sizey = set
                    sjUF:UpdateRaidFrames()
                end
            }
        }
    }
end

function sjUF.InitFrames()
    -- Create frames
    sjUF.frames = {}
    --sjUF.frames.Player = CreateFrame("Button", "sjUF_Player", sjUF.frames.Master)
    --sjUF.frames.Pet    = CreateFrame("Button", "sjUF_Pet", sjUF.frames.Master)
    --sjUF.frames.Target = CreateFrame("Button", "sjUF_Target", sjUF.frames.Master)
    --sjUF.frames.ToT    = CreateFrame("Button", "sjUF_ToT", sjUF.frames.Master)
    --sjUF.frames.ToToT  = CreateFrame("Button", "sjUF_ToToT", sjUF.frames.Master)

    -- RAID

    -- Container
    sjUF.raid = CreateFrame("Frame", "sjUF_Raid", UIParent)
    sjUF.raid:SetClampedToScreen(true)
    sjUF.raid:SetMovable(true)
    sjUF.raid.anchor = CreateFrame("Frame", "sjUF_RaidAnchor", raid)
    sjUF.raid.anchor:SetPoint("TOPLEFT", raid, "TOPLEFT", -5, 5)
    sjUF.raid.anchor:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", 5, -5)
    sjUF.raid.anchor.background = sjUF.raid:CreateTexture(nil, "BACKGROUND")
    sjUF.raid.anchor.background:SetTexture(0.5, 0.5, 0.5, 0.5)
    sjUF.raid.anchor.background:SetAllPoints()
    sjUF.raid.anchor:RegisterForDrag("LeftButton")
    sjUF.raid.anchor:SetScript("OnDragStart", function()
        sjUF.raid:StartMoving()
    end)
    sjUF.raid.anchor:SetScript("OnDragStop", function()
        sjUF.raid:StopMovingOrSizing()
    end)
    function sjUF.raid:Lock(enable)
        if enable == nil then
            enable = not sjUF.opt.raid_lock
        end
        sjUF.opt.raid_lock = enable
        sjUF.raid.anchor:EnableMouse(not enable)
        if enable then
            sjUF.raid.anchor:Hide()
        else
            sjUF.raid.anchor:Show()
        end
    end
    sjUF.raid:Lock(sjUF.opt.raid_lock)

    -- Unit frames
    --raid.units = {}
    --for i = 1, 40 do
    --local f = CreateFrame("Button", "sjUF_Raid"..i, raid)
    --f.hp_bar = CreateFrame("StatusBar", nil, f)
    --f.hp_bar:SetMinMaxValues(0, 100)
    --f.hp_bar:SetFrameLevel(2)
    --f.hp_bar:SetPoint("TOP", f, "TOP")
    --raid.units[i] = f
    --end

    sjUF.UpdateRaidFrames()
end
