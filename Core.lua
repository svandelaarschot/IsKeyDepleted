--[[
================================================================================
Core.lua - IsKeyDepleted Addon Core Module
================================================================================
This module contains the core functionality for the IsKeyDepleted addon including:
- Key depletion detection and tracking
- Death counting and penalty calculations
- Timeability status determination
- Timeline data management
- Abandon button logic
- Debug system with configurable levels
- Database structure and initialization

Author: Alvarín-Silvermoon
Version: 0.1
================================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Use shared namespace
ns = _G[addonName] or ns

-- Create core namespace
ns.Core = ns.Core or {}

-- Local reference for easier access
local Core = ns.Core

-- Import Constants from namespace
local Constants = ns.Constants

-- ============================================================================
-- CONSTANTS AND CONFIGURATION
-- ============================================================================

--[[
    Debug levels for the debug system
    Higher numbers include all lower levels
--]]
local DEBUG_LEVELS = {
    ERROR = 1,      -- Critical errors only
    WARNING = 2,    -- Warnings and errors
    INFO = 3,       -- General information (default)
    DEBUG = 4,      -- Debug information
    VERBOSE = 5     -- Verbose debugging
}

-- ============================================================================
-- DATABASE STRUCTURE
-- ============================================================================

--[[
    Main addon database structure
    This is the persistent storage for all addon data
--]]
IsKeyDepletedDB = IsKeyDepletedDB or {
    settings = {
        hideBlizzardTracker = true,
        deathPenaltySeconds = 5,
        timeabilityThresholds = {
            timeable = 0.8,
            borderline = 0.6,
            notTimeable = 0.4
        }
    },
    timelineHistory = {},
    statistics = {
        totalRuns = 0,
        totalDeaths = 0,
        averageDeaths = 0,
        bestTime = 0
    },
    currentRun = {
        isActive = false,
        startTime = nil,
        keyLevel = nil,
        dungeonId = nil,
        deaths = {},
        bosses = {},
        lastUpdateTime = nil
    },
    options = {
        debugMode = false,
        debugLevel = 3
    },
    version = 1     -- Database version for migration purposes
}

-- ============================================================================
-- DEBUG SYSTEM
-- ============================================================================

--[[
    Main debug print function
    @param level (number) - Debug level (1-5)
    @param message (string) - Message to print
    @param ... (any) - Additional arguments for string formatting
--]]
function Core.DebugPrint(level, message, ...)
    local debugMode = IsKeyDepletedDB.options.debugMode
    if not debugMode then return end
    
    local debugLevel = IsKeyDepletedDB.options.debugLevel
    if not debugLevel then debugLevel = DEBUG_LEVELS.INFO end
    
    if level > debugLevel then return end
    
    local levelNames = {
        [DEBUG_LEVELS.ERROR] = "|cffFF0000[ERROR]|r",
        [DEBUG_LEVELS.WARNING] = "|cffFFA500[WARNING]|r", 
        [DEBUG_LEVELS.INFO] = "|cff39FF14[INFO]|r",
        [DEBUG_LEVELS.DEBUG] = "|cff00FFFF[DEBUG]|r",
        [DEBUG_LEVELS.VERBOSE] = "|cffFF69B4[VERBOSE]|r"
    }
    
    local formattedMessage = string.format(message, ...)
    print("|cff39FF14IsKeyDepleted|r " .. levelNames[level] .. " " .. formattedMessage)
end

--[[
    Convenience functions for different debug levels
    These functions provide easy access to specific debug levels
--]]

--[[
    Print error messages
    @param message (string) - Error message
    @param ... (any) - Additional arguments for string formatting
--]]
function Core.DebugError(message, ...)
    Core.DebugPrint(DEBUG_LEVELS.ERROR, message, ...)
end

--[[
    Print warning messages
    @param message (string) - Warning message
    @param ... (any) - Additional arguments for string formatting
--]]
function Core.DebugWarning(message, ...)
    Core.DebugPrint(DEBUG_LEVELS.WARNING, message, ...)
end

--[[
    Print info messages
    @param message (string) - Info message
    @param ... (any) - Additional arguments for string formatting
--]]
function Core.DebugInfo(message, ...)
    Core.DebugPrint(DEBUG_LEVELS.INFO, message, ...)
end

--[[
    Print debug messages
    @param message (string) - Debug message
    @param ... (any) - Additional arguments for string formatting
--]]
function Core.DebugDebug(message, ...)
    Core.DebugPrint(DEBUG_LEVELS.DEBUG, message, ...)
end

--[[
    Print verbose messages
    @param message (string) - Verbose message
    @param ... (any) - Additional arguments for string formatting
--]]
function Core.DebugVerbose(message, ...)
    Core.DebugPrint(DEBUG_LEVELS.VERBOSE, message, ...)
end

-- ============================================================================
-- DEBUG MANAGEMENT FUNCTIONS
-- ============================================================================

--[[
    Set debug level
    @param level (number) - Debug level (1-5)
--]]
function Core.SetDebugLevel(level)
    if level >= DEBUG_LEVELS.ERROR and level <= DEBUG_LEVELS.VERBOSE then
        IsKeyDepletedDB.options.debugLevel = level
        local levelNames = {"ERROR", "WARNING", "INFO", "DEBUG", "VERBOSE"}
        Core.DebugInfo("Debug level set to: %s", levelNames[level])
    end
end

--[[
    Toggle debug mode on/off
--]]
function Core.ToggleDebugMode()
    IsKeyDepletedDB.options.debugMode = not IsKeyDepletedDB.options.debugMode
    local newMode = IsKeyDepletedDB.options.debugMode
    Core.DebugInfo("Debug mode %s", newMode and "enabled" or "disabled")
end

-- ============================================================================
-- CORE STATE AND VARIABLES
-- ============================================================================

-- Core state
Core.isInitialized = false
Core.currentKey = nil
Core.timelineData = {}
Core.deathCount = 0
Core.startTime = 0
Core.currentTime = 0
Core.totalTime = 1800 -- 30 minutes default
Core.timeabilityStatus = Constants.TIMEABILITY.TIMEABLE

-- ============================================================================
-- CORE INITIALIZATION
-- ============================================================================

--[[
    Initialize core module
    Sets up the core functionality and database
--]]
function Core.Initialize()
    if Core.isInitialized then
        Core.DebugWarning("Core already initialized!")
        return
    end
    
    Core:ResetTimelineData()
    
    -- Try to restore previous run on startup
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    local inFollowerDungeon = C_Scenario.IsInScenario() and C_Scenario.GetInfo()
    
    if inChallengeMode or inFollowerDungeon then
        local restored = Core:RestoreCurrentRun()
        if restored then
            Core.DebugInfo("Restored previous run on startup - %d deaths, %d bosses", Core.deathCount, #Core.timelineData.bosses)
        end
    end
    
    Core.isInitialized = true
    Core.DebugInfo("Core system initialized!")
end

-- Reset timeline data for a new run
function Core:ResetTimelineData()
    self.timelineData = {
        startTime = 0,
        currentTime = 0,
        totalTime = 1800, -- 30 minutes
        deaths = {},
        bosses = {},
        events = {},
        isActive = false
    }
    self.deathCount = 0
    self.startTime = 0
    self.currentTime = 0
    self.timeabilityStatus = Constants.TIMEABILITY.TIMEABLE
    
    Core.DebugDebug("Timeline data reset")
end

-- Start tracking a new key
function Core:StartKeyTracking(keyLevel, dungeonId)
    self:ResetTimelineData()
    self.currentKey = {
        level = keyLevel,
        dungeonId = dungeonId,
        startTime = GetTime()
    }
    
    self.startTime = GetTime()
    self.timelineData.startTime = self.startTime
    self.timelineData.isActive = true
    
    -- Get actual dungeon timer from Blizzard API
    self.totalTime = self:GetDungeonTimer(keyLevel, dungeonId)
    
    self:AddTimelineEvent(Constants.TIMELINE_EVENTS.KEY_START, "Key started", 0)
    
    Core.DebugInfo("Started tracking key level %d, Timer: %s", keyLevel, self:FormatTime(self.totalTime))
end

-- Stop tracking the current key
function Core:StopKeyTracking(reason)
    if not self.timelineData.isActive then
        Core.DebugWarning("Attempted to stop tracking when not active")
        return
    end
    
    self.timelineData.isActive = false
    self.currentTime = GetTime() - self.startTime
    
    self:AddTimelineEvent(Constants.TIMELINE_EVENTS.KEY_END, reason or "Key ended", self.currentTime)
    
    Core.DebugInfo("Stopped tracking key - %s", reason or "Unknown reason")
end

-- Add a death to the timeline
function Core:AddDeath(reason)
    if not self.timelineData.isActive then
        Core.DebugWarning("Attempted to add death when not tracking")
        return
    end
    
    self.deathCount = self.deathCount + 1
    self.currentTime = GetTime() - self.startTime
    
    local deathData = {
        time = self.currentTime,
        reason = reason or "Unknown",
        deathNumber = self.deathCount
    }
    
    table.insert(self.timelineData.deaths, deathData)
    self:AddTimelineEvent(Constants.TIMELINE_EVENTS.DEATH, "Death #" .. self.deathCount .. ": " .. reason, self.currentTime)
    
    -- Update timeability status
    self:UpdateTimeabilityStatus()
    
    Core.DebugInfo("Death #%d at %s", self.deathCount, self:FormatTime(self.currentTime))
end

-- Add a boss kill to the timeline
function Core:AddBossKill(bossName)
    if not self.timelineData.isActive then
        Core.DebugWarning("Attempted to add boss kill when not tracking")
        return
    end
    
    self.currentTime = GetTime() - self.startTime
    
    local bossData = {
        name = bossName,
        time = self.currentTime,
        completed = true
    }
    
    table.insert(self.timelineData.bosses, bossData)
    self:AddTimelineEvent(Constants.TIMELINE_EVENTS.BOSS_KILL, "Boss killed: " .. bossName, self.currentTime)
    
    -- Update timeability status
    self:UpdateTimeabilityStatus()
    
    Core.DebugInfo("Boss killed: %s at %s", bossName, self:FormatTime(self.currentTime))
end

-- Add a timeline event
function Core:AddTimelineEvent(eventType, description, time)
    local event = {
        type = eventType,
        description = description,
        time = time,
        timestamp = GetTime()
    }
    
    table.insert(self.timelineData.events, event)
    Core.DebugVerbose("Timeline event added: %s at %s", description, self:FormatTime(time))
end

-- Update current time (called continuously)
function Core:UpdateCurrentTime()
    if not self.timelineData.isActive or not self.startTime then
        return
    end
    
    self.currentTime = GetTime() - self.startTime
end

-- Update timeability status based on current progress
function Core:UpdateTimeabilityStatus()
    if not self.timelineData.isActive then
        return
    end
    
    self:UpdateCurrentTime()
    
    -- Check if we're in actual challenge mode (M+)
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    
    if not inChallengeMode then
        -- For follower dungeons, normal, heroic, mythic 0 - no timeability status
        self.timeabilityStatus = Constants.TIMEABILITY.UNKNOWN
        return
    end
    
    local remainingTime = self.totalTime - self.currentTime
    local deathPenalty = self.deathCount * Constants.DEATH_PENALTY_SECONDS
    local effectiveRemainingTime = remainingTime - deathPenalty
    
    local timePercentage = effectiveRemainingTime / self.totalTime
    
    local oldStatus = self.timeabilityStatus
    
    if timePercentage >= Constants.TIMEABILITY_THRESHOLDS.TIMEABLE_PERCENTAGE then
        self.timeabilityStatus = Constants.TIMEABILITY.TIMEABLE
    elseif timePercentage >= Constants.TIMEABILITY_THRESHOLDS.BORDERLINE_PERCENTAGE then
        self.timeabilityStatus = Constants.TIMEABILITY.BORDERLINE
    else
        self.timeabilityStatus = Constants.TIMEABILITY.NOT_TIMEABLE
    end
    
    if oldStatus ~= self.timeabilityStatus then
        Core.DebugInfo("Timeability status changed: %s -> %s", oldStatus, self.timeabilityStatus)
    end
end

-- Get current timeability status
function Core:GetTimeabilityStatus()
    return self.timeabilityStatus
end

-- Get death count
function Core:GetDeathCount()
    return self.deathCount
end

-- Get death penalty time (only for M+ dungeons)
function Core:GetDeathPenaltyTime()
    -- Check if we're in actual challenge mode (M+)
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    
    if not inChallengeMode then
        -- For follower dungeons, normal, heroic, mythic 0 - no death penalty
        return 0
    end
    
    -- Only apply death penalty in M+ dungeons
    return self.deathCount * Constants.DEATH_PENALTY_SECONDS
end

-- Get dungeon timer based on key level and dungeon type
function Core:GetDungeonTimer(keyLevel, dungeonId)
    -- Check if we're in actual challenge mode (M+)
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    
    if not inChallengeMode then
        -- For follower dungeons, normal, heroic - no timer
        return 0
    end
    
    -- Base timers for different key levels (M+ only)
    local baseTimers = {
        [2] = 40 * 60,   -- 40 minutes for +2
        [3] = 39 * 60,   -- 39 minutes for +3
        [4] = 38 * 60,   -- 38 minutes for +4
        [5] = 37 * 60,   -- 37 minutes for +5
        [6] = 36 * 60,   -- 36 minutes for +6
        [7] = 35 * 60,   -- 35 minutes for +7
        [8] = 34 * 60,   -- 34 minutes for +8
        [9] = 33 * 60,   -- 33 minutes for +9
        [10] = 32 * 60,  -- 32 minutes for +10
        [11] = 31 * 60,  -- 31 minutes for +11
        [12] = 30 * 60,  -- 30 minutes for +12
        [13] = 29 * 60,  -- 29 minutes for +13
        [14] = 28 * 60,  -- 28 minutes for +14
        [15] = 27 * 60,  -- 27 minutes for +15
        [16] = 26 * 60,  -- 26 minutes for +16
        [17] = 25 * 60,  -- 25 minutes for +17
        [18] = 24 * 60,  -- 24 minutes for +18
        [19] = 23 * 60,  -- 23 minutes for +19
        [20] = 22 * 60,  -- 22 minutes for +20
    }
    
    -- Get timer for key level, default to 30 minutes if not found
    local timer = baseTimers[keyLevel] or (30 * 60)
    
    -- Try to get actual timer from Blizzard API if available
    if C_ChallengeMode.GetActiveKeystoneInfo then
        local keystoneInfo = C_ChallengeMode.GetActiveKeystoneInfo()
        if keystoneInfo and keystoneInfo.timeLimit then
            timer = keystoneInfo.timeLimit
            Core.DebugInfo("Using Blizzard timer: %s", self:FormatTime(timer))
        end
    end
    
    Core.DebugInfo("Dungeon timer for +%d: %s", keyLevel, self:FormatTime(timer))
    return timer
end

-- Get remaining time
function Core:GetRemainingTime()
    if not self.timelineData.isActive or not self.startTime then
        return 0
    end
    
    self.currentTime = GetTime() - self.startTime
    local remainingTime = self.totalTime - self.currentTime
    local deathPenalty = self:GetDeathPenaltyTime()
    
    return math.max(0, remainingTime - deathPenalty)
end

-- Get timeline data for UI
function Core:GetTimelineData()
    return self.timelineData
end

-- Get boss kill information
function Core:GetBossKills()
    if not self.timelineData or not self.timelineData.bosses then
        return {}
    end
    return self.timelineData.bosses
end

-- Get formatted boss list
function Core:GetFormattedBossList()
    local bosses = self:GetBossKills()
    local bossList = {}
    
    for i, boss in ipairs(bosses) do
        table.insert(bossList, {
            name = boss.name,
            time = self:FormatTime(boss.time),
            index = i
        })
    end
    
    return bossList
end

-- Get current progress percentage
function Core:GetProgressPercentage()
    if not self.timelineData.isActive or not self.startTime then
        return 0
    end
    
    self.currentTime = GetTime() - self.startTime
    return math.min(1, self.currentTime / self.totalTime)
end

-- Check if abandon button should be shown
function Core:ShouldShowAbandonButton()
    return self.timeabilityStatus == Constants.TIMEABILITY.BORDERLINE or 
           self.timeabilityStatus == Constants.TIMEABILITY.NOT_TIMEABLE
end

-- Execute abandon command
function Core:ExecuteAbandon()
    if self:ShouldShowAbandonButton() then
        self:StopKeyTracking("Abandoned by player")
        -- Execute the abandon command
        RunMacroText("/abandon")
        Core.DebugInfo("Abandoning key...")
    else
        Core.DebugWarning("Abandon button should not be shown, ignoring abandon request")
    end
end

-- Format time for display
function Core:FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, secs)
end

-- Get timeline statistics
function Core:GetTimelineStats()
    return {
        totalTime = self.totalTime,
        currentTime = self.currentTime,
        remainingTime = self:GetRemainingTime(),
        deathCount = self.deathCount,
        deathPenalty = self:GetDeathPenaltyTime(),
        timeabilityStatus = self.timeabilityStatus,
        progressPercentage = self:GetProgressPercentage(),
        shouldShowAbandon = self:ShouldShowAbandonButton()
    }
end

-- Export timeline data
function Core:ExportTimelineData()
    local exportData = {
        version = 1,
        timestamp = GetTime(),
        key = self.currentKey,
        timeline = self.timelineData,
        stats = self:GetTimelineStats()
    }
    
    Core.DebugDebug("Timeline data exported")
    return exportData
end

-- Save timeline data to SavedVariables
function Core:SaveTimelineData()
    if not self.timelineData.isActive then
        Core.DebugWarning("Attempted to save timeline data when not active")
        return
    end
    
    local runData = {
        timestamp = GetTime(),
        key = self.currentKey,
        timeline = self.timelineData,
        stats = self:GetTimelineStats()
    }
    
    table.insert(IsKeyDepletedDB.timelineHistory, runData)
    
    -- Update statistics
    IsKeyDepletedDB.statistics.totalRuns = IsKeyDepletedDB.statistics.totalRuns + 1
    IsKeyDepletedDB.statistics.totalDeaths = IsKeyDepletedDB.statistics.totalDeaths + self.deathCount
    IsKeyDepletedDB.statistics.averageDeaths = IsKeyDepletedDB.statistics.totalDeaths / IsKeyDepletedDB.statistics.totalRuns
    
    if self.currentTime > 0 and (IsKeyDepletedDB.statistics.bestTime == 0 or self.currentTime < IsKeyDepletedDB.statistics.bestTime) then
        IsKeyDepletedDB.statistics.bestTime = self.currentTime
    end
    
    Core.DebugInfo("Timeline data saved to history")
end

-- Load timeline data from SavedVariables
function Core:LoadTimelineData()
    return IsKeyDepletedDB.timelineHistory
end

-- Get statistics
function Core:GetStatistics()
    return IsKeyDepletedDB.statistics
end

-- Get settings
function Core:GetSettings()
    return IsKeyDepletedDB.settings
end

-- Update settings
function Core:UpdateSettings(newSettings)
    for key, value in pairs(newSettings) do
        IsKeyDepletedDB.settings[key] = value
    end
    Core.DebugInfo("Settings updated")
end

-- Save current run state to SavedVariables
function Core:SaveCurrentRun()
    if not self.timelineData.isActive then
        return
    end
    
    IsKeyDepletedDB.currentRun = {
        isActive = self.timelineData.isActive,
        startTime = self.startTime,
        keyLevel = self.currentKey and self.currentKey.level,
        dungeonId = self.currentKey and self.currentKey.dungeonId,
        deaths = self.timelineData.deaths,
        bosses = self.timelineData.bosses,
        lastUpdateTime = GetTime()
    }
    
    Core.DebugInfo("Current run state saved")
end

-- Restore current run state from SavedVariables
function Core:RestoreCurrentRun()
    local currentRun = IsKeyDepletedDB.currentRun
    if not currentRun or not currentRun.isActive then
        return false
    end
    
    -- Check if we're still in the same dungeon/scenario
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    local inFollowerDungeon = C_Scenario.IsInScenario() and C_Scenario.GetInfo()
    
    if not inChallengeMode and not inFollowerDungeon then
        Core.DebugInfo("Not in dungeon anymore, clearing saved run")
        self:ClearCurrentRun()
        return false
    end
    
    -- Restore the run state
    self.timelineData.isActive = currentRun.isActive
    self.startTime = currentRun.startTime
    self.timelineData.deaths = currentRun.deaths or {}
    self.timelineData.bosses = currentRun.bosses or {}
    
    if currentRun.keyLevel and currentRun.dungeonId then
        self.currentKey = {
            level = currentRun.keyLevel,
            dungeonId = currentRun.dungeonId
        }
    end
    
    -- Update death count
    self.deathCount = #self.timelineData.deaths
    
    Core.DebugInfo("Current run state restored - %d deaths, %d bosses", self.deathCount, #self.timelineData.bosses)
    return true
end

-- Clear current run from SavedVariables
function Core:ClearCurrentRun()
    IsKeyDepletedDB.currentRun = {
        isActive = false,
        startTime = nil,
        keyLevel = nil,
        dungeonId = nil,
        deaths = {},
        bosses = {},
        lastUpdateTime = nil
    }
    Core.DebugInfo("Current run cleared")
end

-- Update core system (called regularly)
function Core:Update()
    if not self.timelineData.isActive then
        return
    end
    
    self:UpdateTimeabilityStatus()
    
    -- Save state periodically
    if GetTime() - (self.lastSaveTime or 0) > 5 then -- Save every 5 seconds
        self:SaveCurrentRun()
        self.lastSaveTime = GetTime()
    end
    
    Core.DebugVerbose("Core update - Status: %s, Deaths: %d, Time: %s", 
        self.timeabilityStatus, self.deathCount, self:FormatTime(self.currentTime))
end

-- Assign to namespace
ns.Core = Core