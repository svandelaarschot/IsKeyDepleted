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

-- Create core namespace
ns.Core = ns.Core or {}

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
function ns.Core.DebugPrint(level, message, ...)
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
function ns.Core.DebugError(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.ERROR, message, ...)
end

--[[
    Print warning messages
    @param message (string) - Warning message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugWarning(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.WARNING, message, ...)
end

--[[
    Print info messages
    @param message (string) - Info message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugInfo(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.INFO, message, ...)
end

--[[
    Print debug messages
    @param message (string) - Debug message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugDebug(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.DEBUG, message, ...)
end

--[[
    Print verbose messages
    @param message (string) - Verbose message
    @param ... (any) - Additional arguments for string formatting
--]]
function ns.Core.DebugVerbose(message, ...)
    ns.Core.DebugPrint(DEBUG_LEVELS.VERBOSE, message, ...)
end

-- ============================================================================
-- DEBUG MANAGEMENT FUNCTIONS
-- ============================================================================

--[[
    Set debug level
    @param level (number) - Debug level (1-5)
--]]
function ns.Core.SetDebugLevel(level)
    if level >= DEBUG_LEVELS.ERROR and level <= DEBUG_LEVELS.VERBOSE then
        IsKeyDepletedDB.options.debugLevel = level
        local levelNames = {"ERROR", "WARNING", "INFO", "DEBUG", "VERBOSE"}
        ns.Core.DebugInfo("Debug level set to: %s", levelNames[level])
    end
end

--[[
    Toggle debug mode on/off
--]]
function ns.Core.ToggleDebugMode()
    IsKeyDepletedDB.options.debugMode = not IsKeyDepletedDB.options.debugMode
    local newMode = IsKeyDepletedDB.options.debugMode
    ns.Core.DebugInfo("Debug mode %s", newMode and "enabled" or "disabled")
end

-- ============================================================================
-- CORE STATE AND VARIABLES
-- ============================================================================

-- Core state
ns.Core.isInitialized = false
ns.Core.currentKey = nil
ns.Core.timelineData = {}
ns.Core.deathCount = 0
ns.Core.startTime = 0
ns.Core.currentTime = 0
ns.Core.totalTime = 1800 -- 30 minutes default
ns.Core.timeabilityStatus = Constants.TIMEABILITY.TIMEABLE

-- ============================================================================
-- CORE INITIALIZATION
-- ============================================================================

--[[
    Initialize core module
    Sets up the core functionality and database
--]]
function ns.Core.Initialize()
    if ns.Core.isInitialized then
        ns.Core.DebugWarning("Core already initialized!")
        return
    end
    
    ns.Core:ResetTimelineData()
    ns.Core.isInitialized = true
    
    ns.Core.DebugInfo("Core system initialized!")
end

-- Reset timeline data for a new run
function ns.Core:ResetTimelineData()
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
    
    ns.Core.DebugDebug("Timeline data reset")
end

-- Start tracking a new key
function ns.Core:StartKeyTracking(keyLevel, dungeonId)
    self:ResetTimelineData()
    self.currentKey = {
        level = keyLevel,
        dungeonId = dungeonId,
        startTime = GetTime()
    }
    
    self.startTime = GetTime()
    self.timelineData.startTime = self.startTime
    self.timelineData.isActive = true
    
    self:AddTimelineEvent(Constants.TIMELINE_EVENTS.KEY_START, "Key started", 0)
    
    ns.Core.DebugInfo("Started tracking key level %d", keyLevel)
end

-- Stop tracking the current key
function ns.Core:StopKeyTracking(reason)
    if not self.timelineData.isActive then
        ns.Core.DebugWarning("Attempted to stop tracking when not active")
        return
    end
    
    self.timelineData.isActive = false
    self.currentTime = GetTime() - self.startTime
    
    self:AddTimelineEvent(Constants.TIMELINE_EVENTS.KEY_END, reason or "Key ended", self.currentTime)
    
    ns.Core.DebugInfo("Stopped tracking key - %s", reason or "Unknown reason")
end

-- Add a death to the timeline
function ns.Core:AddDeath(reason)
    if not self.timelineData.isActive then
        ns.Core.DebugWarning("Attempted to add death when not tracking")
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
    
    ns.Core.DebugInfo("Death #%d at %s", self.deathCount, self:FormatTime(self.currentTime))
end

-- Add a boss kill to the timeline
function ns.Core:AddBossKill(bossName)
    if not self.timelineData.isActive then
        ns.Core.DebugWarning("Attempted to add boss kill when not tracking")
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
    
    ns.Core.DebugInfo("Boss killed: %s at %s", bossName, self:FormatTime(self.currentTime))
end

-- Add a timeline event
function ns.Core:AddTimelineEvent(eventType, description, time)
    local event = {
        type = eventType,
        description = description,
        time = time,
        timestamp = GetTime()
    }
    
    table.insert(self.timelineData.events, event)
    ns.Core.DebugVerbose("Timeline event added: %s at %s", description, self:FormatTime(time))
end

-- Update timeability status based on current progress
function ns.Core:UpdateTimeabilityStatus()
    if not self.timelineData.isActive then
        return
    end
    
    self.currentTime = GetTime() - self.startTime
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
        ns.Core.DebugInfo("Timeability status changed: %s -> %s", oldStatus, self.timeabilityStatus)
    end
end

-- Get current timeability status
function ns.Core:GetTimeabilityStatus()
    return self.timeabilityStatus
end

-- Get death count
function ns.Core:GetDeathCount()
    return self.deathCount
end

-- Get death penalty time
function ns.Core:GetDeathPenaltyTime()
    return self.deathCount * Constants.DEATH_PENALTY_SECONDS
end

-- Get remaining time
function ns.Core:GetRemainingTime()
    if not self.timelineData.isActive then
        return 0
    end
    
    self.currentTime = GetTime() - self.startTime
    local remainingTime = self.totalTime - self.currentTime
    local deathPenalty = self:GetDeathPenaltyTime()
    
    return math.max(0, remainingTime - deathPenalty)
end

-- Get timeline data for UI
function ns.Core:GetTimelineData()
    return self.timelineData
end

-- Get current progress percentage
function ns.Core:GetProgressPercentage()
    if not self.timelineData.isActive then
        return 0
    end
    
    self.currentTime = GetTime() - self.startTime
    return math.min(1, self.currentTime / self.totalTime)
end

-- Check if abandon button should be shown
function ns.Core:ShouldShowAbandonButton()
    return self.timeabilityStatus == Constants.TIMEABILITY.BORDERLINE or 
           self.timeabilityStatus == Constants.TIMEABILITY.NOT_TIMEABLE
end

-- Execute abandon command
function ns.Core:ExecuteAbandon()
    if self:ShouldShowAbandonButton() then
        self:StopKeyTracking("Abandoned by player")
        -- Execute the abandon command
        RunMacroText("/abandon")
        ns.Core.DebugInfo("Abandoning key...")
    else
        ns.Core.DebugWarning("Abandon button should not be shown, ignoring abandon request")
    end
end

-- Format time for display
function ns.Core:FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, secs)
end

-- Get timeline statistics
function ns.Core:GetTimelineStats()
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
function ns.Core:ExportTimelineData()
    local exportData = {
        version = 1,
        timestamp = GetTime(),
        key = self.currentKey,
        timeline = self.timelineData,
        stats = self:GetTimelineStats()
    }
    
    ns.Core.DebugDebug("Timeline data exported")
    return exportData
end

-- Save timeline data to SavedVariables
function ns.Core:SaveTimelineData()
    if not self.timelineData.isActive then
        ns.Core.DebugWarning("Attempted to save timeline data when not active")
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
    
    ns.Core.DebugInfo("Timeline data saved to history")
end

-- Load timeline data from SavedVariables
function ns.Core:LoadTimelineData()
    return IsKeyDepletedDB.timelineHistory
end

-- Get statistics
function ns.Core:GetStatistics()
    return IsKeyDepletedDB.statistics
end

-- Get settings
function ns.Core:GetSettings()
    return IsKeyDepletedDB.settings
end

-- Update settings
function ns.Core:UpdateSettings(newSettings)
    for key, value in pairs(newSettings) do
        IsKeyDepletedDB.settings[key] = value
    end
    ns.Core.DebugInfo("Settings updated")
end

-- Update core system (called regularly)
function ns.Core:Update()
    if not self.timelineData.isActive then
        return
    end
    
    self:UpdateTimeabilityStatus()
    ns.Core.DebugVerbose("Core update - Status: %s, Deaths: %d, Time: %s", 
        self.timeabilityStatus, self.deathCount, self:FormatTime(self.currentTime))
end