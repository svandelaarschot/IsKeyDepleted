-- IsKeyDepleted Constants
-- Configuration values and constants for the addon

local Constants = {}

-- Addon Information
Constants.ADDON_NAME = "IsKeyDepleted"
Constants.ADDON_VERSION = "0.1"
Constants.ADDON_AUTHOR = "Alvarín-Silvermoon"

-- Key Status Constants
Constants.KEY_STATUS = {
    ACTIVE = "ACTIVE",
    DEPLETED = "DEPLETED",
    COMPLETED = "COMPLETED",
    ABANDONED = "ABANDONED"
}

-- Timeability Status
Constants.TIMEABILITY = {
    TIMEABLE = "TIMEABLE",      -- Green
    BORDERLINE = "BORDERLINE",  -- Yellow
    NOT_TIMEABLE = "NOT_TIMEABLE" -- Red
}

-- Death Tracking
Constants.DEATH_PENALTY_SECONDS = 5
Constants.MAX_DEATHS_DISPLAY = 10
Constants.DEATH_MARKER_SIZE = 8

-- Timeline Configuration
Constants.TIMELINE = {
    WIDTH = 400,
    HEIGHT = 60,
    PROGRESS_BAR_HEIGHT = 20,
    MARKER_SIZE = 12,
    TIME_LABEL_HEIGHT = 16,
    DEATH_MARKER_COLOR = {r = 1, g = 0, b = 0, a = 1}, -- Red
    BOSS_MARKER_COLOR = {r = 0, g = 1, b = 0, a = 1},  -- Green
    CURRENT_POSITION_COLOR = {r = 1, g = 1, b = 0, a = 1}, -- Yellow
    PROGRESS_BAR_COLOR = {r = 0.2, g = 0.6, b = 1, a = 0.8},
    BACKGROUND_COLOR = {r = 0.1, g = 0.1, b = 0.1, a = 0.8}
}

-- UI Colors
Constants.COLORS = {
    TIMEABLE = {r = 0, g = 1, b = 0, a = 1},      -- Green
    BORDERLINE = {r = 1, g = 1, b = 0, a = 1},    -- Yellow
    NOT_TIMEABLE = {r = 1, g = 0, b = 0, a = 1},  -- Red
    NEUTRAL = {r = 1, g = 1, b = 1, a = 1},       -- White
    WARNING = {r = 1, g = 0.5, b = 0, a = 1}      -- Orange
}

-- Timeline Events
Constants.TIMELINE_EVENTS = {
    DEATH = "DEATH",
    BOSS_KILL = "BOSS_KILL",
    TRASH_CLEAR = "TRASH_CLEAR",
    KEY_START = "KEY_START",
    KEY_END = "KEY_END"
}

-- Boss Information (will be populated dynamically)
Constants.BOSSES = {
    -- This will be populated based on the dungeon
    -- Example structure:
    -- [dungeonId] = {
    --     {name = "Boss 1", expectedTime = 120},
    --     {name = "Boss 2", expectedTime = 300},
    --     {name = "Boss 3", expectedTime = 600},
    --     {name = "Boss 4", expectedTime = 900}
    -- }
}

-- Timeability Thresholds
Constants.TIMEABILITY_THRESHOLDS = {
    TIMEABLE_PERCENTAGE = 0.8,    -- 80% of time remaining
    BORDERLINE_PERCENTAGE = 0.6,  -- 60% of time remaining
    NOT_TIMEABLE_PERCENTAGE = 0.4 -- 40% of time remaining
}

-- UI Positioning
Constants.UI_POSITIONS = {
    TIMELINE = {
        x = 0,
        y = 0,
        anchor = "CENTER"
    },
    MAIN_FRAME = {
        x = 0,
        y = 0,
        anchor = "CENTER"
    }
}

-- Slash Commands
Constants.COMMANDS = {
    MAIN = "iskd",
    ABANDON = "abandon",
    RESET = "reset",
    TOGGLE = "toggle",
    CONFIG = "config"
}

-- Saved Variables
Constants.SAVED_VARIABLES = {
    DATABASE = "IsKeyDepletedDB"
}

-- Timeline Animation
Constants.ANIMATION = {
    UPDATE_INTERVAL = 0.1, -- Update every 100ms
    SMOOTH_TRANSITION = true,
    MARKER_ANIMATION = true
}

-- Export/Import
Constants.EXPORT = {
    VERSION = 1,
    FORMAT = "json"
}

-- Blizzard Tracker Control
Constants.BLIZZARD_TRACKER = {
    HIDE_BY_DEFAULT = true,
    MONITOR_INTERVAL = 0.1, -- Check every 100ms
    FRAMES_TO_HIDE = {
        "ChallengeModeFrame",
        "ChallengeModeTimerFrame", 
        "ChallengeModeScoreFrame",
        "ChallengeModeLeaderboardFrame"
    }
}

-- Make Constants available in namespace
local addonName, ns = ...
ns.Constants = Constants

return Constants
