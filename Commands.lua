--[[
================================================================================
Commands.lua - IsKeyDepleted Addon Command System
================================================================================
This module handles all slash commands and user interaction including:
- Slash command registration and handling
- UI control commands
- Status reporting and debugging
- Test functions and data export

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

-- Create commands namespace
ns.Commands = ns.Commands or {}

-- Local reference for easier access
local Commands = ns.Commands

-- Make Commands globally accessible for slash commands
_G.IsKeyDepletedCommands = ns.Commands

-- Import other modules from namespace
local Constants = ns.Constants
local Core = ns.Core
local UI = ns.UI
local Events = ns.Events

-- ============================================================================
-- USER MESSAGE FUNCTIONS
-- ============================================================================

--[[
    Print user-facing messages
    These are messages that should always be shown to the user
    @param message (string) - Message to print
    @param ... (any) - Additional arguments for string formatting
--]]
function Commands:UserPrint(message, ...)
    local formattedMessage = string.format(message, ...)
    print("|cff39FF14IsKeyDepleted|r: " .. formattedMessage)
end

-- Initialize the command system
function Commands:Initialize()
    Core.DebugInfo("Commands:Initialize() called")
    self:RegisterSlashCommands()
    Core.DebugInfo("Commands:Initialize() completed")
    Core.DebugInfo("Command system initialized")
end

-- Register slash commands
function Commands:RegisterSlashCommands()
    Core.DebugInfo("Registering slash commands...")
    Core.DebugInfo("Constants.COMMANDS.MAIN = %s", Constants.COMMANDS.MAIN)
    
    -- Debug: Check if Constants is properly loaded
    if not Constants or not Constants.COMMANDS then
        Core.DebugError("Constants.COMMANDS not found! Constants = %s", tostring(Constants))
        return
    end
    
    -- Main command
    SLASH_ISKEYDEPLETED1 = "/" .. Constants.COMMANDS.MAIN
    SLASH_ISKEYDEPLETED2 = "/iskd"
    SLASH_ISKEYDEPLETED3 = "/isk"
    
    SlashCmdList["ISKEYDEPLETED"] = function(msg)
        Core.DebugInfo("Slash command triggered with message: %s", msg or "nil")
        if _G.IsKeyDepletedCommands then
            Core.DebugInfo("Commands module found, handling command...")
            _G.IsKeyDepletedCommands:HandleCommand(msg)
        else
            Core.DebugError("Commands module not loaded!")
        end
    end
    
    Core.DebugInfo("Slash commands registered: /%s, /iskd, /isk", Constants.COMMANDS.MAIN)
end

-- Handle slash commands
function Commands:HandleCommand(msg)
    Core.DebugInfo("HandleCommand called with: %s", msg or "nil")
    Core.DebugInfo("Slash command received: '%s'", msg or "nil")
    local args = self:ParseCommand(msg)
    local command = args[1] and args[1]:lower() or ""
    
    Core.DebugInfo("Parsed command: '%s'", command)
    
    if command == "toggle" or command == "t" then
        self:ToggleUI()
    elseif command == "show" or command == "s" then
        self:ShowUI()
    elseif command == "hide" or command == "h" then
        self:HideUI()
    elseif command == "status" or command == "stat" then
        self:ShowStatus()
    elseif command == "abandon" or command == "a" then
        self:AbandonKey()
    elseif command == "reset" or command == "r" then
        self:ResetTimeline()
    elseif command == "export" or command == "e" then
        self:ExportData()
    elseif command == "test" then
        self:RunTests()
    elseif command == "tracker" then
        self:ToggleBlizzardTracker()
    elseif command == "help" or command == "h" or command == "" then
        self:ShowHelp()
    else
        Core.DebugWarning("Unknown command: %s. Use /iskd help for available commands.", command or "nil")
    end
end

-- Parse command arguments
function Commands:ParseCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    return args
end

-- Toggle UI
function Commands:ToggleUI()
    UI:Toggle()
    Core.DebugInfo("UI toggled")
end

-- Show UI
function Commands:ShowUI()
    UI:Show()
    Core.DebugInfo("UI shown")
end

-- Hide UI
function Commands:HideUI()
    UI:Hide()
    Core.DebugInfo("UI hidden")
end

-- Show status
function Commands:ShowStatus()
    local stats = Core:GetTimelineStats()
    local timelineData = Core:GetTimelineData()
    
    Core.DebugInfo("Status command executed - gathering timeline data")
    
    self:UserPrint("=== Status Report ===")
    self:UserPrint("Timeability: %s", stats.timeabilityStatus)
    self:UserPrint("Deaths: %d (+%ds penalty)", stats.deathCount, stats.deathPenalty)
    self:UserPrint("Remaining Time: %s", Core:FormatTime(stats.remainingTime))
    self:UserPrint("Progress: %d%%", math.floor(stats.progressPercentage * 100))
    self:UserPrint("Active: %s", timelineData.isActive and "Yes" or "No")
    
    if #timelineData.deaths > 0 then
        self:UserPrint("Death History:")
        for i, death in ipairs(timelineData.deaths) do
            self:UserPrint("  %d. %s - %s", i, Core:FormatTime(death.time), death.reason)
        end
    end
    
    if #timelineData.bosses > 0 then
        self:UserPrint("Bosses Killed:")
        for i, boss in ipairs(timelineData.bosses) do
            self:UserPrint("  %d. %s at %s", i, boss.name, Core:FormatTime(boss.time))
        end
    end
    
    Core.DebugInfo("Status report displayed - %d deaths, %d bosses, %s timeability", 
        stats.deathCount, #timelineData.bosses, stats.timeabilityStatus)
end

-- Abandon key
function Commands:AbandonKey()
    Core.DebugInfo("Abandon command executed - checking if abandon is allowed")
    
    if Core:ShouldShowAbandonButton() then
        Core:ExecuteAbandon()
        self:UserPrint("Abandoning key...")
        Core.DebugInfo("Abandon key command executed - key was not timeable")
    else
        self:UserPrint("Key is still timeable! Abandon button not available.")
        Core.DebugWarning("Abandon requested but key is still timeable - status: %s", Core:GetTimeabilityStatus())
    end
end

-- Reset timeline
function Commands:ResetTimeline()
    Core.DebugInfo("Reset command executed - clearing timeline data")
    Core:ResetTimelineData()
    self:UserPrint("Timeline reset")
    Core.DebugInfo("Timeline reset command executed - all data cleared")
end

-- Export data
function Commands:ExportData()
    Core.DebugInfo("Export command executed - gathering timeline data for export")
    local exportData = Core:ExportTimelineData()
    
    self:UserPrint("=== Export Data ===")
    self:UserPrint("Version: %d", exportData.version)
    self:UserPrint("Timestamp: %s", date("%Y-%m-%d %H:%M:%S", exportData.timestamp))
    
    if exportData.key then
        self:UserPrint("Key Level: %d", exportData.key.level)
        self:UserPrint("Dungeon ID: %d", exportData.key.dungeonId)
    end
    
    self:UserPrint("Deaths: %d", #exportData.timeline.deaths)
    self:UserPrint("Bosses: %d", #exportData.timeline.bosses)
    self:UserPrint("Events: %d", #exportData.timeline.events)
    
    Core.DebugInfo("Data export completed - %d deaths, %d bosses, %d events, version %d", 
        #exportData.timeline.deaths, #exportData.timeline.bosses, #exportData.timeline.events, exportData.version)
end

-- Run tests
function Commands:RunTests()
    Core.DebugInfo("Test command executed - starting test sequence")
    self:UserPrint("=== Running Tests ===")
    Core.DebugInfo("Starting test sequence - will test key start, death, boss kill, and key stop")
    
    -- Test start key
    self:UserPrint("Testing key start...")
    Events:TestStartKey()
    Core.DebugInfo("Test key start executed")
    
    -- Wait a moment
    C_Timer.After(1, function()
        self:UserPrint("Testing death...")
        Events:TestDeath()
        Core.DebugInfo("Test death executed")
        
        C_Timer.After(1, function()
            self:UserPrint("Testing boss kill...")
            Events:TestBossKill()
            Core.DebugInfo("Test boss kill executed")
            
            C_Timer.After(1, function()
                self:UserPrint("Testing key stop...")
                Events:TestStopKey()
                self:UserPrint("Tests completed!")
                Core.DebugInfo("Test sequence completed successfully - all test events executed")
            end)
        end)
    end)
end

-- Toggle Blizzard tracker
function Commands:ToggleBlizzardTracker()
    UI:ToggleBlizzardTracker()
    local status = UI:IsBlizzardTrackerHidden() and "hidden" or "shown"
    self:UserPrint("Blizzard tracker %s", status)
    Core.DebugInfo("Blizzard tracker toggled - %s (user requested)", status)
end

-- Show help
function Commands:ShowHelp()
    self:UserPrint("=== Available Commands ===")
    self:UserPrint("/iskd toggle - Toggle the UI")
    self:UserPrint("/iskd show - Show the UI")
    self:UserPrint("/iskd hide - Hide the UI")
    self:UserPrint("/iskd status - Show current status")
    self:UserPrint("/iskd abandon - Abandon current key")
    self:UserPrint("/iskd reset - Reset timeline data")
    self:UserPrint("/iskd export - Export timeline data")
    self:UserPrint("/iskd test - Run test scenarios")
    self:UserPrint("/iskd tracker - Toggle Blizzard tracker")
    self:UserPrint("/iskd help - Show this help")
    self:UserPrint("=== Shortcuts ===")
    self:UserPrint("/iskd t - Toggle UI")
    self:UserPrint("/iskd s - Show UI")
    self:UserPrint("/iskd h - Hide UI")
    self:UserPrint("/iskd stat - Show status")
    self:UserPrint("/iskd a - Abandon key")
    self:UserPrint("/iskd r - Reset timeline")
    self:UserPrint("/iskd e - Export data")
    
    Core.DebugInfo("Help command executed - displayed all available commands and shortcuts")
end

-- Assign to namespace
ns.Commands = Commands