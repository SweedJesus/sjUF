-- TODO:
-- More modular coloring system (static, class)
-- Fix name text formatting, since "short" is only really for raid frames
-- Use text table in styles instead of static strings

-- Resources
local font_myriad           = "Interface\\AddOns\\sjUF\\media\\fonts\\myriad.ttf"
local font_visitor          = "Interface\\AddOns\\sjUF\\media\\fonts\\visitor.ttf"
local font_steelfish        = "Interface\\AddOns\\sjUF\\media\\fonts\\steelfish.ttf"
local font_tork             = "Interface\\AddOns\\sjUF\\media\\fonts\\tork.ttf"
local texture_flat          = "Interface\\AddOns\\sjUF\\media\\textures\\Flat.tga"
local texture_solid         = "Interface\\AddOns\\sjUF\\media\\textures\\Solid.tga"
local texture_smooth        = "Interface\\AddOns\\sjUF\\media\\textures\\Smooth.tga"
local background_ui_tooltip = "Interface\\Tooltips\\UI-Tooltip-Background"
local border_ui_tooltip     = "Interface\\Tooltips\\UI-Tooltip-Border"
local border_grid           = "Interface\\AddOns\\sjUF\\media\\borders\\UI-Tooltip-Border_Grid.tga"

local self = sjUF

-- Fonts
self.fonts = {
    [font_myriad]    = "Myriad",
    [font_visitor]   = "Visitor",
    [font_steelfish] = "Steelfish",
    [font_tork]      = "Tork",
}

-- Status bar textures
self.textures = {
    [texture_flat]   = "Flat",
    [texture_solid]  = "Solid",
    [texture_smooth] = "Smooth"
}

-- Backdrop background textures
self.background_textures = {
    [background_ui_tooltip] = "UI Tooltip"
}

-- Backdrop border textures
self.borders = {
    [border_ui_tooltip] = "UI Tooltip",
    [border_grid]       = "Grid"
}

-- Default configurations
self.defaults = {
    lock = true,
    dummy_units = true,
    colors = {
        default = { r = 0.75, g = 0.75, b = 0.75 },
        classes = {
            ["DRUID"]   = { r = 1.00, g = 0.49, b = 0.04 },
            ["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45 },
            ["MAGE"]    = { r = 0.41, g = 0.8,  b = 0.94 },
            ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
            ["PRIEST"]  = { r = 1.00, g = 1.00, b = 1.00 },
            ["ROGUE"]   = { r = 1.00, g = 0.96, b = 0.41 },
            ["SHAMAN"]  = { r = 0.00, g = 0.44, b = 0.87 },
            ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
            ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 }
        },
        powers = {
            -- 0 = mana, 1 = rage, 2 = focus, 3 = energy
            [0] = { r = 0.18, g = 0.45, b = 0.75 },
            [1] = { r = 0.89, g = 0.18, b = 0.29 },
            [2] = { r = 1.00, g = 0.70, b = 0.00 },
            [3] = { r = 1.00, g = 1.00, b = 0.13 }
        },
    },
    player = {
        rested_icon = {
            enabled = true
        },
        pvp_rank_icon = {
            enabled = true
        },
        style = {
            frame = {
                width = 240,
                height = 100,
                xoffset = 0,
                yoffset = 0
            },
            backdrop = {
                background_enabled = true,
                background_texture = background_ui_tooltip,
                background_inset = 5,
                edge_enabled = true,
                edge_texture = border_grid,
                edge_inset = 10
            },
            hp_bar = {
                class_color = true,
                texture = texture_solid,
                height_weight = 11
            },
            mp_bar = {
                enabled = true,
                texture = texture_flat,
                height_weight = 1
            },
            name_text = {
                enabled = true,
                font = font_myriad,
                font_size = 10,
                xoffset = 2,
                yoffset = -2,
                hjust = "LEFT",
                short = false,
                short_num_chars = 5
            },
            hp_text = {
                enabled = true,
                xoffset = 2,
                yoffset = -14,
                font = font_myriad,
                font_size = 8,
                hjust = "CENTER"
            },
            mp_text = {
                enabled = false,
                xoffset = 2,
                yoffset = -18,
                font = font_myriad,
                font_size = 8,
                hjust = "CENTER"
            }
        }
    },
    target = { style = {} },
    raid = {
        units_per_row = 8,
        units_xoffset = 5,
        units_yoffset = 5,
        style = {
            frame = {
                width = 40,
                height = 30,
                xoffset = 0,
                yoffset = 0
            },
            backdrop = {
                background_enabled = true,
                background_texture = background_ui_tooltip,
                background_inset = 5,
                edge_enabled = true,
                edge_texture = border_grid,
                edge_inset = 10
            },
            hp_bar = {
                class_color = true,
                texture = texture_solid,
                height_weight = 11
            },
            mp_bar = {
                enabled = true,
                texture = texture_flat,
                height_weight = 1
            },
            name_text = {
                enabled = true,
                font = font_myriad,
                font_size = 10,
                xoffset = 2,
                yoffset = -2,
                hjust = "LEFT",
                short = false,
                short_num_chars = 5
            },
            hp_text = {
                enabled = true,
                xoffset = 2,
                yoffset = -14,
                font = font_myriad,
                font_size = 8,
                hjust = "CENTER"
            },
            mp_text = {
                enabled = false,
                xoffset = 2,
                yoffset = -18,
                font = font_myriad,
                font_size = 8,
                hjust = "CENTER"
            }
        }
    }
}

local function GetColor(c)
    assert(c)
    return c.r, c.g, c.b
end

local function SetColor(c, r, g, b)
    assert(c)
    c.r, c.g, c.b = r, g, b
    self:UpdateRaidFrames()
end

-- @param a Original
-- @param b Table to fill
local function Copy(a, b)
    for k,v in pairs(a) do
        if (type(v) == "table") then
            Copy(a[k], b[k])
        else
            b[k] = a[k]
        end
    end
end

-- Configuration options
self.options = {
    type = "group",
    args = {
        locked = {
            name = "Toggle lock",
            desc = "Toggle lock of frames",
            type = "toggle",
            get = function()
                return self.opt.locked
            end,
            set = function(set)
                self.opt.locked = set
                --self:UpdateRaidFrames()
            end
        },
        colors = {
            name = "Colors",
            desc = "Color configuration",
            type = "group",
            args = {
                default = {
                    name = "Default",
                    desc = "Set the default color",
                    type = "color",
                    get = function()
                        return GetColor(self.opt.colors.default)
                    end,
                    set = function(r, g, b)
                        SetColor(self.opt.colors.default, r, g, b)
                    end,
                    hasAlpha = false
                },
                classes = {
                    name = "Classes",
                    desc = "Class colors",
                    type = "group",
                    args = {
                        druid = {
                            name = "Druid",
                            desc = "Set druid color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.DRUID)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.DRUID, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        hunter = {
                            name = "Hunter",
                            desc = "Set hunter color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.HUNTER)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.HUNTER, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        mage = {
                            name = "Mage",
                            desc = "Set mage color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.MAGE)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.MAGE, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        paladin = {
                            name = "Paladin",
                            desc = "Set paladin color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.PALADIN)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.PALADIN, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        priest = {
                            name = "Priest",
                            desc = "Set priest color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.PRIEST)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.PRIEST, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        rogue = {
                            name = "Rogue",
                            desc = "Set rogue color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.ROGUE)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.ROGUE, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        shaman = {
                            name = "Shaman",
                            desc = "Set shaman color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.SHAMAN)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.SHAMAN, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        warlock = {
                            name = "Warlock",
                            desc = "Set warlock color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.WARLOCK)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.WARLOCK, r, g, b)
                            end,
                            hasAlpha = false
                        },
                        warrior = {
                            name = "Warrior",
                            desc = "Set warrior color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.classes.WARRIOR)
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.classes.WARRIOR, r, g, b)
                            end,
                            hasAlpha = false
                        }
                    }
                },
                powers = {
                    name = "Powers",
                    desc = "Power colors",
                    type = "group",
                    args = {
                        mana = {
                            name = "Mana",
                            desc = "Set mana color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.powers[0])
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.powers[0], r, g, b)
                            end,
                            hasAlpha = false
                        },
                        rage = {
                            name = "Rage",
                            desc = "Set rage color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.powers[1])
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.powers[1], r, g, b)
                            end,
                            hasAlpha = false
                        },
                        focus = {
                            name = "Focus",
                            desc = "Set focus color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.powers[2])
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.powers[2], r, g, b)
                            end,
                            hasAlpha = false
                        },
                        energy = {
                            name = "Energy",
                            desc = "Set energy color",
                            type = "color",
                            get = function()
                                return GetColor(self.opt.colors.powers[3])
                            end,
                            set = function(r, g, b)
                                SetColor(self.opt.colors.powers[3], r, g, b)
                            end,
                            hasAlpha = false
                        }
                    }
                },
                reset = {
                    name = "Reset",
                    desc = "Reset power colors to addon defaults",
                    type = "execute",
                    func = function()
                        Copy(self.defaults.colors, self.opt.colors)
                        self:UpdateRaidFrames()
                    end
                }
            }
        },
        raid = {
            name = "Raid",
            desc = "Raid configuration",
            type = "group",
            args = {
                units_per_row = {
                    name = "Units per row",
                    desc = "Raid member unit frames to show per row",
                    type = "range",
                    min = 1,
                    max = 40,
                    step = 1,
                    get = function()
                        return self.opt.raid.units_per_row
                    end,
                    set = function(set)
                        self.opt.raid.units_per_row = set
                        self:UpdateRaidFrames()
                    end
                },
                unit_frames = {
                    name = "Unit frames",
                    desc = "Unit frame configuration",
                    type = "group",
                    args = {
                        width = {
                            name = "Width",
                            desc = "Set raid unit frame width",
                            type = "range",
                            min = 1,
                            max = 100,
                            step = 1,
                            get = function()
                                return self.opt.raid.style.frame.width
                            end,
                            set = function(set)
                                self.opt.raid.style.frame.width = set
                                self:UpdateRaidFrames()
                            end
                        },
                        height = {
                            name = "Height",
                            desc = "Set raid unit frame height",
                            type = "range",
                            min = 1,
                            max = 100,
                            step = 1,
                            get = function()
                                return self.opt.raid.style.frame.height
                            end,
                            set = function(set)
                                self.opt.raid.style.frame.height = set
                                self:UpdateRaidFrames()
                            end
                        },
                        xoffset = {
                            name = "Frame horizontal spacing",
                            desc = "Horizontal spacing between raid unit frames",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function() return self.opt.raid.style.xoffset end,
                            set = function(set)
                                self.opt.raid.style.xoffset = set
                                self:UpdateRaidFrames()
                            end
                        },
                        yoffset = {
                            name = "Frame vertical spacing",
                            desc = "Vertical spacing between raid unit frames",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function() return self.opt.raid.style.yoffset end,
                            set = function(set)
                                self.opt.raid.style.yoffset = set
                                self:UpdateRaidFrames()
                            end
                        }
                    }
                },
                --backdrop = {
                --name = "Backdrop",
                --desc = "Backdrop configuration",
                --type = "group",
                --args = {
                --background_enabled = {
                --name = "Toggle background",
                --desc = "Toggle displaying the backdrop background",
                --get = function()
                --return self.opt.raid.backdrop.background_enabled
                --end,
                --set = function(set)
                --self.opt.raid.backdrop.background_enabled = set
                --self:UpdateRaidFrames()
                --end
                --},
                --background_texture = {
                --name = "Background texture",
                --desc = "Set the backdrop background texture",
                --type = "text",
                --get = function()
                --return self.opt.raid.backdrop.background_texture
                --end,
                --set = function(set)
                --self.opt.raid.backdrop.background_texture = set
                --self:UpdateRaidFrames()
                --end,
                --validate = self.background_textures
                --},
                --background_inset = {
                --name = "Background inset",
                --desc = "Set the backdrop background inset",
                --type = "range",
                --min = -50,
                --max = 50,
                --step = 1,
                --get = function()
                --return self.opt.raid.backdrop.background_inset
                --end,
                --set = function(set)
                --self.opt.raid.backdrop.background_inset = set
                --self:UpdateRaidFrames()
                --end
                --},
                --edge_enabled = {
                --name = "Toggle border",
                --desc = "Toggle displaying the backdrop border",
                --type = "toggle",
                --get = function()
                --return self.opt.raid.backdrop.edge_enabled
                --end,
                --set = function(set)
                --self.opt.raid.backdrop.edge_enabled = set
                --self:UpdateRaidFrames()
                --end
                --},
                --edge_texture = {
                --name = "Border texture",
                --desc = "Set the backdrop border texture",
                --type = "text",
                --get = function()
                --return self.opt.raid.backdrop.edge_texture
                --end,
                --set = function(set)
                --self.opt.raid.backdrop.edge_texture = set
                --self:UpdateRaidFrames()
                --end,
                --validate = self.borders
                --}
                --}
                --},
                --hp_bar = {
                --name = "Health bar",
                --desc = "Health bar configuration",
                --type = "group",
                --args = {
                --class_color = {
                --name = "Toggle class color",
                --desc = "Toggle coloring health by unit class",
                --type = "toggle",
                --get = function()
                --return self.opt.raid.hp_bar.class_color
                --end,
                --set = function(set)
                --self.opt.raid.hp_bar.class_color = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --texture = {
                --name = "Texture",
                --desc = "Set the status bar texture",
                --type = "text",
                --get = function()
                --return self.opt.raid.hp_bar_texture
                --end,
                --set = function(set)
                --self.opt.raid.hp_bar_texture = set
                --self:UpdateRaidFrames()
                --end,
                --validate = self.textures,
                --},
                --height_weight = {
                --name = "Height weight",
                --desc = "Status bar height scaling weight",
                --type = "range",
                --min = 1,
                --max = 20,
                --step = 1,
                --get = function()
                --return self.opt.raid.hp_bar_height_weight
                --end,
                --set = function(set)
                --self.opt.raid.hp_bar_height_weight = set
                --self:UpdateRaidFrames()
                --end,
                --}                    }
                --},
                --mp_bar = {
                --name = "Power bar",
                --desc = "Power bar configuration",
                --type = "group",
                --args = {
                --enabled = {
                --name = "Enabled",
                --desc = "Draw power bar for raid frames",
                --type = "toggle",
                --get = function()
                --return self.opt.raid.mp_bar_enabled
                --end,
                --set = function(set)
                --self.opt.raid.mp_bar_enabled = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --texture = {
                --name = "Texture",
                --desc = "Status bar texture",
                --type = "text",
                --get = function()
                --return self.opt.raid.mp_bar_texture
                --end,
                --set = function(set)
                --self.opt.raid.mp_bar_texture = set
                --self:UpdateRaidFrames()
                --end,
                --validate = self.textures,
                --},
                --height_weight = {
                --name = "Height weight",
                --desc = "Status bar height scaling weight",
                --type = "range",
                --min = 1,
                --max = 20,
                --step = 1,
                --get = function()
                --return self.opt.raid.mp_bar_height_weight
                --end,
                --set = function(set)
                --self.opt.raid.mp_bar_height_weight = set
                --self:UpdateRaidFrames()
                --end,
                --}
                --}
                --},
                --name_text = {
                --name = "Name text",
                --desc = "Name text configuration",
                --type = "group",
                --args = {
                --enabled = {
                --name = "Enabled",
                --desc = "Name text enabled",
                --type = "toggle",
                --get = function()
                --return self.opt.raid.name_enabled
                --end,
                --set = function(set)
                --self.opt.raid.name_enabled = set
                --self:UpdateRaidFrames()
                --end
                --},
                --font = {
                --name = "Font",
                --desc = "Name text font",
                --type = "text",
                --get = function()
                --return self.opt.raid.name_font
                --end,
                --set = function(set)
                --self.opt.raid.name_font = set
                --self:UpdateRaidFrames()
                --end,
                --validate = self.fonts,
                --},
                --size = {
                --name = "Size",
                --desc = "Name text font size",
                --type = "range",
                --min = 1,
                --max = 24,
                --step = 1,
                --get = function()
                --return self.opt.raid.name_font_size
                --end,
                --set = function(set)
                --self.opt.raid.name_font_size = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --short = {
                --name = "Short names",
                --desc = "Display short names",
                --type = "toggle",
                --get = function()
                --return self.opt.raid.name_short
                --end,
                --set = function(set)
                --self.opt.raid.name_short = set
                --self:UpdateRaidUnits()
                --end,
                --},
                --short_chars = {
                --name = "Short name length",
                --desc = "Number of characters to display in short names",
                --type = "range",
                --min = 1,
                --max = 12,
                --step = 1,
                --get = function()
                --return self.opt.raid.name_short_chars
                --end,
                --set = function(set)
                --self.opt.raid.name_short_chars = set
                --self:UpdateRaidUnits()
                --end,
                --},
                --xoffset = {
                --name = "Horizontal offset",
                --desc = "Name text horizontal offset from the top left corner",
                --type = "range",
                --min = -50,
                --max = 50,
                --step = 1,
                --get = function()
                --return self.opt.raid.name_xoffset
                --end,
                --set = function(set)
                --self.opt.raid.name_xoffset = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --yoffset = {
                --name = "Vertical offset",
                --desc = "Name text vertical offset from the top left corner",
                --type = "range",
                --min = -50,
                --max = 50,
                --step = 1,
                --get = function()
                --return self.opt.raid.name_yoffset
                --end,
                --set = function(set)
                --self.opt.raid.name_yoffset = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --hjust = {
                --name = "Justification",
                --desc = "Name text horizontal justification",
                --type = "text",
                --get = function()
                --return self.opt.raid.name_hjust
                --end,
                --set = function(set)
                --self.opt.raid.name_hjust = set
                --self:UpdateRaidFrames()
                --end,
                --validate = { "LEFT", "CENTER", "RIGHT" },
                --}
                --}
                --},
                --hp_text = {
                --name = "Health text",
                --desc = "Health text configuration",
                --type = "group",
                --args = {
                --enabled = {
                --name = "Enabled",
                --desc = "Health text enabled",
                --type = "toggle",
                --get = function()
                --return self.opt.raid.hp_text_enabled
                --end,
                --set = function(set)
                --self.opt.raid.hp_text_enabled = set
                --self:UpdateRaidFrames()
                --end
                --},
                --font = {
                --name = "Font",
                --desc = "Health text font",
                --type = "text",
                --get = function()
                --return self.opt.raid.hp_text_font
                --end,
                --set = function(set)
                --self.opt.raid.hp_text_font = set
                --self:UpdateRaidFrames()
                --end,
                --validate = self.fonts,
                --},
                --size = {
                --name = "Size",
                --desc = "Health text font size",
                --type = "range",
                --min = 1,
                --max = 24,
                --step = 1,
                --get = function()
                --return self.opt.raid.hp_text_font_size
                --end,
                --set = function(set)
                --self.opt.raid.hp_text_font_size = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --xoffset = {
                --name = "Horizontal offset",
                --desc = "Health text horizontal offset from the top left corner",
                --type = "range",
                --min = -50,
                --max = 50,
                --step = 1,
                --get = function()
                --return self.opt.raid.hp_text_xoffset
                --end,
                --set = function(set)
                --self.opt.raid.hp_text_xoffset = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --yoffset = {
                --name = "Vertical offset",
                --desc = "Health text vertical offset from the top left corner",
                --type = "range",
                --min = -50,
                --max = 50,
                --step = 1,
                --get = function()
                --return self.opt.raid.hp_text_yoffset
                --end,
                --set = function(set)
                --self.opt.raid.hp_text_yoffset = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --hjust = {
                --name = "Justification",
                --desc = "Health text horizontal justification",
                --type = "text",
                --get = function()
                --return self.opt.raid.hp_text_hjust
                --end,
                --set = function(set)
                --self.opt.raid.hp_text_hjust = set
                --self:UpdateRaidFrames()
                --end,
                --validate = { "LEFT", "CENTER", "RIGHT" },
                --}
                --}
                --},
                --mp_text = {
                --name = "Power text",
                --desc = "Power text configuration",
                --type = "group",
                --args = {
                --enabled = {
                --name = "Enabled",
                --desc = "Power text enabled",
                --type = "toggle",
                --get = function()
                --return self.opt.raid.mp_text_enabled
                --end,
                --set = function(set)
                --self.opt.raid.mp_text_enabled = set
                --self:UpdateRaidFrames()
                --end
                --},
                --font = {
                --name = "Font",
                --desc = "Power text font",
                --type = "text",
                --get = function()
                --return self.opt.raid.mp_text_font
                --end,
                --set = function(set)
                --self.opt.raid.mp_text_font = set
                --self:UpdateRaidFrames()
                --end,
                --validate = self.fonts,
                --},
                --size = {
                --name = "Size",
                --desc = "Power text font size",
                --type = "range",
                --min = 1,
                --max = 24,
                --step = 1,
                --get = function()
                --return self.opt.raid.mp_text_font_size
                --end,
                --set = function(set)
                --self.opt.raid.mp_text_font_size = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --xoffset = {
                --name = "Horizontal offset",
                --desc = "Power text horizontal offset from the top left corner",
                --type = "range",
                --min = -50,
                --max = 50,
                --step = 1,
                --get = function()
                --return self.opt.raid.mp_text_xoffset
                --end,
                --set = function(set)
                --self.opt.raid.mp_text_xoffset = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --yoffset = {
                --name = "Vertical offset",
                --desc = "Power text vertical offset from the top left corner",
                --type = "range",
                --min = -50,
                --max = 50,
                --step = 1,
                --get = function()
                --return self.opt.raid.mp_text_yoffset
                --end,
                --set = function(set)
                --self.opt.raid.mp_text_yoffset = set
                --self:UpdateRaidFrames()
                --end,
                --},
                --hjust = {
                --name = "Justification",
                --desc = "Power text horizontal justification",
                --type = "text",
                --get = function()
                --return self.opt.raid.mp_text_hjust
                --end,
                --set = function(set)
                --self.opt.raid.mp_text_hjust = set
                --self:UpdateRaidFrames()
                --self:UpdateRaidUnits()
                --end,
                --validate = { "LEFT", "CENTER", "RIGHT" },
                --}
                --}
                --}
                --}
            },
        }
    }
}
