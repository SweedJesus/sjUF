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
self.backgrounds = {
    [background_ui_tooltip] = "UI Tooltip"
}

-- Backdrop border textures
self.borders = {
    [border_ui_tooltip] = "UI Tooltip",
    [border_grid]       = "Grid"
}

-- Default configurations
self.defaults = {
    dummy_units = true,
    power_colors = {
        mana      = { r = 0.18, g = 0.45, b = 0.75 },
        rage      = { r = 0.89, g = 0.18, b = 0.29 },
        energy    = { r = 1.00, g = 1.00, b = 0.13 },
        focus     = { r = 1.00, g = 0.70, b = 0.00 },
        happiness = { r = 0.00, g = 1.00, b = 1.00 }
    },
    raid = {
        -- Layout
        width = 40,
        height = 30,
        units_per_row = 8,
        xoffset = 5,
        yoffset = 5,
        -- Backdrop
        background_enabled = true,
        background_texture = background_ui_tooltip,
        border_enabled = true,
        border_texture = border_grid,
        border_size = 16,
        border_inset = 5,
        -- HP bar
        hp_bar_texture = texture_flat,
        hp_bar_class_color = true,
        hp_bar_height_weight = 11,
        -- MP bar
        mp_bar_enabled = true,
        mp_bar_texture = texture_flat,
        mp_bar_height_weight = 1,
        -- Name text
        name_enabled = true,
        name_font = font_myriad,
        name_font_size = 10,
        name_short = false,
        name_short_chars = 5,
        name_xoffset = 2,
        name_yoffset = -2,
        name_hjust = "LEFT",
        -- HP text
        hp_text_enabled = true,
        hp_text_xoffset = 2,
        hp_text_yoffset = -14,
        hp_text_font = font_myriad,
        hp_text_font_size = 8,
        hp_text_hjust = "CENTER",
        -- MP text
        mp_text_enabled = false,
        mp_text_xoffset = 2,
        mp_text_yoffset = -16,
        mp_text_font = font_myriad,
        mp_text_font_size = 8,
        mp_text_hjust = "CENTER"
    }
}

-- Configuration options
self.options = {
    type = "group",
    args = {
        power_colors = {
            name = "Power colors",
            desc = "Colors for class power (mana, energy, rage)",
            type = "group",
            args = {
                mana = {
                    name = "Mana",
                    desc = "Mana color",
                    type = "color",
                    get = function()
                        return self:GetPowerColor("mana")
                    end,
                    set = function(r, g, b)
                        self:SetPowerColor("mana", r, g, b)
                        self:UpdateRaidFrames()
                    end,
                    hasAlpha = false
                },
                rage = {
                    name = "Rage",
                    desc = "Rage color",
                    type = "color",
                    get = function()
                        return self:GetPowerColor("rage")
                    end,
                    set = function(r, g, b)
                        self:SetPowerColor("rage", r, g, b)
                        self:UpdateRaidFrames()
                    end,
                    hasAlpha = false
                },
                energy = {
                    name = "Energy",
                    desc = "Energy color",
                    type = "color",
                    get = function()
                        return self:GetPowerColor("energy")
                    end,
                    set = function(r, g, b)
                        self:SetPowerColor("energy", r, g, b)
                        self:UpdateRaidFrames()
                    end,
                    hasAlpha = false
                },
                focus = {
                    name = "Focus",
                    desc = "Focus color",
                    type = "color",
                    get = function()
                        return self:GetPowerColor("focus")
                    end,
                    set = function(r, g, b)
                        self:SetPowerColor("focus", r, g, b)
                        self:UpdateRaidFrames()
                    end,
                    hasAlpha = false
                },
                happiness = {
                    name = "Happiness",
                    desc = "Happiness color",
                    type = "color",
                    get = function()
                        return self:GetPowerColor("happiness")
                    end,
                    set = function(r, g, b)
                        self:SetPowerColor("happiness", r, g, b)
                        self:UpdateRaidFrames()
                    end,
                    hasAlpha = false
                },
                default = {
                    name = "Default",
                    desc = "Reset power colors to addon defaults",
                    type = "execute",
                    func = function()
                        self:SetPowerColor("mana",      0.18, 0.45, 0.75)
                        self:SetPowerColor("rage",      0.89, 0.18, 0.29)
                        self:SetPowerColor("energy",    1.00, 1.00, 0.13)
                        self:SetPowerColor("focus",     1.00, 0.70, 0.00)
                        self:SetPowerColor("happiness", 0.00, 1.00, 1.00)
                        self:UpdateRaidFrames()
                    end
                }
            }
        },
        raid = {
            name = "Raid",
            desc = "Raid frames configuration",
            type = "group",
            args = {
                width = {
                    name = "Raid unit frame width",
                    desc = "Width of each raid member unit frame",
                    type = "range",
                    min = 1,
                    max = 100,
                    step = 1,
                    get = function() return self.opt.raid.width end,
                    set = function(set)
                        self.opt.raid.width = set
                        self:UpdateRaidFrames()
                    end
                },
                height = {
                    name = "Raid unit frame height",
                    desc = "Height of each raid member unit frame",
                    type = "range",
                    min = 1,
                    max = 100,
                    step = 1,
                    get = function() return self.opt.raid.height end,
                    set = function(set)
                        self.opt.raid.height = set
                        self:UpdateRaidFrames()
                    end
                },
                backdrop = {
                    name = "Backdrop",
                    desc = "Backdrop configuration",
                    type = "group",
                    args = {
                        background = {
                            name = "Background",
                            desc = "Backdrop background configuration (you may not be able to see this if health bars of opaque)",
                            type = "group",
                            args = {
                                enabled = {
                                    name = "Enabled",
                                    desc = "Backdrop background enabled",
                                    type = "toggle",
                                    get = function()
                                        return self.opt.raid.background_enabled
                                    end,
                                    set = function(set)
                                        self.opt.raid.background_enabled = set
                                        self:UpdateRaidFrames()
                                    end
                                },
                                texture = {
                                    name = "Texture",
                                    desc = "Backdrop background texture",
                                    type = "text",
                                    get = function()
                                        return self.opt.raid.background_texture
                                    end,
                                    set = function(set)
                                        self.opt.raid.background_texture = set
                                        self:UpdateRaidFrames()
                                    end,
                                    validate = self.backgrounds
                                }
                            }
                        },
                        border = {
                            name = "Border",
                            desc = "Backdrop border configuration",
                            type = "group",
                            args = {
                                enabled = {
                                    name = "Enabled",
                                    desc = "Backdrop border enabled",
                                    type = "toggle",
                                    get = function()
                                        return self.opt.raid.border_enabled
                                    end,
                                    set = function(set)
                                        self.opt.raid.border_enabled = set
                                        self:UpdateRaidFrames()
                                    end
                                },
                                texture = {
                                    name = "Texture",
                                    desc = "Backdrop border texture",
                                    type = "text",
                                    get = function()
                                        return self.opt.raid.border_texture
                                    end,
                                    set = function(set)
                                        self.opt.raid.border_texture = set
                                        self:UpdateRaidFrames()
                                    end,
                                    validate = self.borders
                                }
                            }
                        },
                        inset = {
                            name = "Inset",
                            desc = "Backdrop inset",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function()
                                return self.opt.raid.border_inset
                            end,
                            set = function(set)
                                self.opt.raid.border_inset = set
                                self:UpdateRaidFrames()
                            end
                        }
                    }
                },
                units_per_row = {
                    name = "Units per row",
                    desc = "Raid member unit frames to show per row",
                    type = "range",
                    min = 1,
                    max = 40,
                    step = 1,
                    get = function() return self.opt.raid.units_per_row end,
                    set = function(set)
                        self.opt.raid.units_per_row = set
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
                    get = function() return self.opt.raid.xoffset end,
                    set = function(set)
                        self.opt.raid.xoffset = set
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
                    get = function() return self.opt.raid.yoffset end,
                    set = function(set)
                        self.opt.raid.yoffset = set
                        self:UpdateRaidFrames()
                    end
                },
                name_text = {
                    name = "Name text",
                    desc = "Name text configuration",
                    type = "group",
                    args = {
                        enabled = {
                            name = "Enabled",
                            desc = "Name text enabled",
                            type = "toggle",
                            get = function()
                                return self.opt.raid.name_enabled
                            end,
                            set = function(set)
                                self.opt.raid.name_enabled = set
                                self:UpdateRaidFrames()
                            end
                        },
                        font = {
                            name = "Font",
                            desc = "Name text font",
                            type = "text",
                            get = function()
                                return self.opt.raid.name_font
                            end,
                            set = function(set)
                                self.opt.raid.name_font = set
                                self:UpdateRaidFrames()
                            end,
                            validate = self.fonts,
                        },
                        size = {
                            name = "Size",
                            desc = "Name text font size",
                            type = "range",
                            min = 1,
                            max = 24,
                            step = 1,
                            get = function()
                                return self.opt.raid.name_font_size
                            end,
                            set = function(set)
                                self.opt.raid.name_font_size = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        short = {
                            name = "Short names",
                            desc = "Display short names",
                            type = "toggle",
                            get = function()
                                return self.opt.raid.name_short
                            end,
                            set = function(set)
                                self.opt.raid.name_short = set
                                self:UpdateRaidUnits()
                            end,
                        },
                        short_chars = {
                            name = "Short name length",
                            desc = "Number of characters to display in short names",
                            type = "range",
                            min = 1,
                            max = 12,
                            step = 1,
                            get = function()
                                return self.opt.raid.name_short_chars
                            end,
                            set = function(set)
                                self.opt.raid.name_short_chars = set
                                self:UpdateRaidUnits()
                            end,
                        },
                        xoffset = {
                            name = "Horizontal offset",
                            desc = "Name text horizontal offset from the top left corner",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function()
                                return self.opt.raid.name_xoffset
                            end,
                            set = function(set)
                                self.opt.raid.name_xoffset = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        yoffset = {
                            name = "Vertical offset",
                            desc = "Name text vertical offset from the top left corner",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function()
                                return self.opt.raid.name_yoffset
                            end,
                            set = function(set)
                                self.opt.raid.name_yoffset = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        hjust = {
                            name = "Justification",
                            desc = "Name text horizontal justification",
                            type = "text",
                            get = function()
                                return self.opt.raid.name_hjust
                            end,
                            set = function(set)
                                self.opt.raid.name_hjust = set
                                self:UpdateRaidFrames()
                            end,
                            validate = { "LEFT", "CENTER", "RIGHT" },
                        }
                    }
                },
                hp_text = {
                    name = "Health text",
                    desc = "Health text configuration",
                    type = "group",
                    args = {
                        enabled = {
                            name = "Enabled",
                            desc = "Health text enabled",
                            type = "toggle",
                            get = function()
                                return self.opt.raid.hp_text_enabled
                            end,
                            set = function(set)
                                self.opt.raid.hp_text_enabled = set
                                self:UpdateRaidFrames()
                            end
                        },
                        font = {
                            name = "Font",
                            desc = "Health text font",
                            type = "text",
                            get = function()
                                return self.opt.raid.hp_text_font
                            end,
                            set = function(set)
                                self.opt.raid.hp_text_font = set
                                self:UpdateRaidFrames()
                            end,
                            validate = self.fonts,
                        },
                        size = {
                            name = "Size",
                            desc = "Health text font size",
                            type = "range",
                            min = 1,
                            max = 24,
                            step = 1,
                            get = function()
                                return self.opt.raid.hp_text_font_size
                            end,
                            set = function(set)
                                self.opt.raid.hp_text_font_size = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        xoffset = {
                            name = "Horizontal offset",
                            desc = "Health text horizontal offset from the top left corner",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function()
                                return self.opt.raid.hp_text_xoffset
                            end,
                            set = function(set)
                                self.opt.raid.hp_text_xoffset = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        yoffset = {
                            name = "Vertical offset",
                            desc = "Health text vertical offset from the top left corner",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function()
                                return self.opt.raid.hp_text_yoffset
                            end,
                            set = function(set)
                                self.opt.raid.hp_text_yoffset = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        hjust = {
                            name = "Justification",
                            desc = "Health text horizontal justification",
                            type = "text",
                            get = function()
                                return self.opt.raid.hp_text_hjust
                            end,
                            set = function(set)
                                self.opt.raid.hp_text_hjust = set
                                self:UpdateRaidFrames()
                            end,
                            validate = { "LEFT", "CENTER", "RIGHT" },
                        }
                    }
                },
                mp_text = {
                    name = "Power text",
                    desc = "Power text configuration",
                    type = "group",
                    args = {
                        enabled = {
                            name = "Enabled",
                            desc = "Power text enabled",
                            type = "toggle",
                            get = function()
                                return self.opt.raid.mp_text_enabled
                            end,
                            set = function(set)
                                self.opt.raid.mp_text_enabled = set
                                self:UpdateRaidFrames()
                            end
                        },
                        font = {
                            name = "Font",
                            desc = "Power text font",
                            type = "text",
                            get = function()
                                return self.opt.raid.mp_text_font
                            end,
                            set = function(set)
                                self.opt.raid.mp_text_font = set
                                self:UpdateRaidFrames()
                            end,
                            validate = self.fonts,
                        },
                        size = {
                            name = "Size",
                            desc = "Power text font size",
                            type = "range",
                            min = 1,
                            max = 24,
                            step = 1,
                            get = function()
                                return self.opt.raid.mp_text_font_size
                            end,
                            set = function(set)
                                self.opt.raid.mp_text_font_size = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        xoffset = {
                            name = "Horizontal offset",
                            desc = "Power text horizontal offset from the top left corner",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function()
                                return self.opt.raid.mp_text_xoffset
                            end,
                            set = function(set)
                                self.opt.raid.mp_text_xoffset = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        yoffset = {
                            name = "Vertical offset",
                            desc = "Power text vertical offset from the top left corner",
                            type = "range",
                            min = -50,
                            max = 50,
                            step = 1,
                            get = function()
                                return self.opt.raid.mp_text_yoffset
                            end,
                            set = function(set)
                                self.opt.raid.mp_text_yoffset = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        hjust = {
                            name = "Justification",
                            desc = "Power text horizontal justification",
                            type = "text",
                            get = function()
                                return self.opt.raid.mp_text_hjust
                            end,
                            set = function(set)
                                self.opt.raid.mp_text_hjust = set
                                self:UpdateRaidFrames()
                                self:UpdateRaidUnits()
                            end,
                            validate = { "LEFT", "CENTER", "RIGHT" },
                        }
                    }
                },
                hp_bar = {
                    name = "Health bar",
                    desc = "Health bar configuration",
                    type = "group",
                    args = {
                        texture = {
                            name = "Texture",
                            desc = "Status bar texture",
                            type = "text",
                            get = function()
                                return self.opt.raid.hp_bar_texture
                            end,
                            set = function(set)
                                self.opt.raid.hp_bar_texture = set
                                self:UpdateRaidFrames()
                            end,
                            validate = self.textures,
                        },
                        height_weight = {
                            name = "Height weight",
                            desc = "Status bar height scaling weight",
                            type = "range",
                            min = 1,
                            max = 20,
                            step = 1,
                            get = function()
                                return self.opt.raid.hp_bar_height_weight
                            end,
                            set = function(set)
                                self.opt.raid.hp_bar_height_weight = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        class_color = {
                            name = "Class color",
                            desc = "Color by unit class",
                            type = "toggle",
                            get = function()
                                return self.opt.raid.hp_bar_class_color
                            end,
                            set = function(set)
                                self.opt.raid.hp_bar_class_color = set
                                self:UpdateRaidFrames()
                            end,
                        }
                    }
                },
                mp_bar = {
                    name = "Power bar",
                    desc = "Power bar configuration",
                    type = "group",
                    args = {
                        enabled = {
                            name = "Enabled",
                            desc = "Draw power bar for raid frames",
                            type = "toggle",
                            get = function()
                                return self.opt.raid.mp_bar_enabled
                            end,
                            set = function(set)
                                self.opt.raid.mp_bar_enabled = set
                                self:UpdateRaidFrames()
                            end,
                        },
                        texture = {
                            name = "Texture",
                            desc = "Status bar texture",
                            type = "text",
                            get = function()
                                return self.opt.raid.mp_bar_texture
                            end,
                            set = function(set)
                                self.opt.raid.mp_bar_texture = set
                                self:UpdateRaidFrames()
                            end,
                            validate = self.textures,
                        },
                        height_weight = {
                            name = "Height weight",
                            desc = "Status bar height scaling weight",
                            type = "range",
                            min = 1,
                            max = 20,
                            step = 1,
                            get = function()
                                return self.opt.raid.mp_bar_height_weight
                            end,
                            set = function(set)
                                self.opt.raid.mp_bar_height_weight = set
                                self:UpdateRaidFrames()
                            end,
                        }
                    }
                }
            }
        },
        reset = {
            name = "Reset",
            desc = "Reset all configurable options to layout defaults",
            type = "execute",
            func = function()
                self:ResetLayout()
                self:UpdateRaidFrames()
                self:UpdateRaidUnits()
            end,
        }
    }
}
