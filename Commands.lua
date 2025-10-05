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
    if Core and Core.DebugInfo then
        Core.DebugInfo("Commands:Initialize() called")
    end
    self:RegisterSlashCommands()
    if Core and Core.DebugInfo then
        Core.DebugInfo("Commands:Initialize() completed")
    end
    if Core and Core.DebugInfo then
        Core.DebugInfo("Command system initialized")
    end
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
    elseif command == "force" or command == "f" then
        self:ForceUI()
    elseif command == "normal" or command == "n" then
        self:NormalUI()
    elseif command == "debug" or command == "d" then
        self:DebugUI()
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
    elseif command == "start" or command == "s" then
        self:StartTimer()
    elseif command == "follower" or command == "f" then
        self:StartFollowerTest()
    elseif command == "restore" or command == "r" then
        self:RestoreRun()
    elseif command == "bosses" or command == "b" then
        self:ShowBosses()
    elseif command == "testtimer" or command == "tt" then
        self:TestTimer()
    elseif command == "errors" or command == "err" then
        self:ToggleLuaErrors()
    elseif command == "disable" or command == "d" then
        self:DisableAddon()
    elseif command == "gui" or command == "g" then
        if Core and Core.DebugInfo then
            Core.DebugInfo("GUI command recognized, calling TestGUI")
        end
        self:UserPrint("GUI command received!")
        self:TestGUI()
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
    local ui = ns.UI
    if ui then
        ui:Toggle()
        Core.DebugInfo("UI toggled")
    else
        self:UserPrint("ERROR: UI module not available!")
    end
end

-- Show UI
function Commands:ShowUI()
    local ui = ns.UI
    if ui then
        ui:Show()
        self:UserPrint("UI shown - should be visible now")
        self:UserPrint("UI position: RIGHT side of screen")
        self:UserPrint("If not visible, try /iskd toggle")
        self:UserPrint("Use /iskd force to keep UI visible for testing")
        Core.DebugInfo("UI shown")
    else
        self:UserPrint("ERROR: UI module not available!")
    end
end

-- Force UI to stay visible (for testing)
function Commands:ForceUI()
    local ui = ns.UI
    if not ui then
        self:UserPrint("ERROR: UI module not available!")
        Core.DebugError("UI module not available in ForceUI")
        return
    end
    
    if not ui.mainFrame then
        self:UserPrint("ERROR: UI mainFrame not created!")
        Core.DebugError("UI mainFrame not available in ForceUI")
        return
    end
    
    ui:Show()
    ui.mainFrame:SetFrameStrata("HIGH")
    ui.mainFrame:SetFrameLevel(200)
    ui.isForced = true  -- Set forced flag
    self:UserPrint("UI forced visible - will stay on screen")
    self:UserPrint("Use /iskd normal to return to normal behavior")
    Core.DebugInfo("UI forced visible")
end

-- Return UI to normal behavior
function Commands:NormalUI()
    local ui = ns.UI
    if not ui or not ui.mainFrame then
        self:UserPrint("ERROR: UI module or mainFrame not available!")
        Core.DebugError("UI module or mainFrame not available in NormalUI")
        return
    end
    
    ui.mainFrame:SetFrameStrata("MEDIUM")
    ui.mainFrame:SetFrameLevel(100)
    ui.isForced = false  -- Clear forced flag
    self:UserPrint("UI returned to normal behavior")
    Core.DebugInfo("UI returned to normal")
end

-- Debug UI status
function Commands:DebugUI()
    local ui = ns.UI
    self:UserPrint("=== UI Debug Information ===")
    self:UserPrint("UI Module Available: %s", tostring(ui ~= nil))
    
    if ui then
        self:UserPrint("UI Initialized: %s", tostring(ui.isInitialized))
        self:UserPrint("Main Frame Available: %s", tostring(ui.mainFrame ~= nil))
        
        if ui.mainFrame then
            self:UserPrint("Main Frame Visible: %s", tostring(ui.mainFrame:IsVisible()))
            self:UserPrint("Main Frame Strata: %s", tostring(ui.mainFrame:GetFrameStrata()))
            self:UserPrint("Main Frame Level: %s", tostring(ui.mainFrame:GetFrameLevel()))
            
            local point, relativeTo, relativePoint, xOfs, yOfs = ui.mainFrame:GetPoint()
            self:UserPrint("Main Frame Position: %s, %s, %s, %s, %s", 
                tostring(point), tostring(relativeTo), tostring(relativePoint), tostring(xOfs), tostring(yOfs))
        end
    end
    
    self:UserPrint("Challenge Mode Active: %s", tostring(C_ChallengeMode.IsChallengeModeActive()))
    self:UserPrint("=== End Debug ===")
    Core.DebugInfo("UI debug information displayed")
end

-- Hide UI
function Commands:HideUI()
    local ui = ns.UI
    if ui then
        ui:Hide()
        Core.DebugInfo("UI hidden")
    else
        self:UserPrint("ERROR: UI module not available!")
    end
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

-- Start timer manually
function Commands:StartTimer()
    Core.DebugInfo("Start timer command executed")
    
    if C_ChallengeMode.IsChallengeModeActive() then
        local keyLevel = C_ChallengeMode.GetActiveKeystoneLevel()
        local dungeonId = C_ChallengeMode.GetActiveKeystoneMapID()
        
        if keyLevel and dungeonId then
            Core:StartKeyTracking(keyLevel, dungeonId)
            UI:Show()
            self:UserPrint("Timer started manually - Key Level %d", keyLevel)
            Core.DebugInfo("Manual timer start - Key Level %d", keyLevel)
        else
            self:UserPrint("Not in a valid challenge mode")
        end
    else
        -- Start with test data
        Core:StartKeyTracking(15, 1) -- Test key level 15, dungeon ID 1
        UI:Show()
        self:UserPrint("Timer started with test data")
        Core.DebugInfo("Manual timer start with test data")
    end
end

-- Start follower dungeon test
function Commands:StartFollowerTest()
    Core.DebugInfo("Start follower test command executed")
    
    local ui = ns.UI
    if not ui then
        self:UserPrint("ERROR: UI module not available!")
        return
    end
    
    -- Start with test data for follower dungeons
    Core:StartKeyTracking(15, 1) -- Test key level 15, dungeon ID 1
    ui:Show()
    ui.isForced = true  -- Keep it visible for testing
    self:UserPrint("Follower dungeon test started - Key Level 15")
    self:UserPrint("UI forced visible for testing")
    Core.DebugInfo("Follower dungeon test started")
end

-- Restore previous run
function Commands:RestoreRun()
    Core.DebugInfo("Restore run command executed")
    
    local ui = ns.UI
    if not ui then
        self:UserPrint("ERROR: UI module not available!")
        return
    end
    
    local restored = Core:RestoreCurrentRun()
    if restored then
        ui:Show()
        ui.isForced = true  -- Keep it visible for testing
        self:UserPrint("Run restored - %d deaths, %d bosses", Core.deathCount, #Core.timelineData.bosses)
        self:UserPrint("Timer: %s", Core:FormatTime(Core.currentTime))
        Core.DebugInfo("Run restored successfully")
    else
        self:UserPrint("No previous run to restore")
        Core.DebugInfo("No previous run found to restore")
    end
end

-- Show boss information
function Commands:ShowBosses()
    Core.DebugInfo("Show bosses command executed")
    
    local bossList = Core:GetFormattedBossList()
    
    if #bossList > 0 then
        self:UserPrint("=== Boss Kills ===")
        for i, boss in ipairs(bossList) do
            self:UserPrint("%d. %s - %s", i, boss.name, boss.time)
        end
        Core.DebugInfo("Boss list displayed - %d bosses killed", #bossList)
    else
        self:UserPrint("No bosses killed yet")
        Core.DebugInfo("Boss list empty - no bosses killed")
    end
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
    
    -- Show UI for testing
    self:UserPrint("Showing timeline UI...")
    UI:Show()
    
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
                
                -- Test UI interactions
                C_Timer.After(1, function()
                    self:UserPrint("Testing UI interactions...")
                    self:TestUIInteractions()
                end)
            end)
        end)
    end)
end

-- Test UI interactions
function Commands:TestUIInteractions()
    self:UserPrint("Testing timeline UI interactions...")
    
    -- Test timeline click
    if UI.timelineFrame then
        self:UserPrint("Testing timeline click...")
        UI:OnTimelineClick()
    end
    
    -- Test abandon button
    if UI.abandonButton then
        self:UserPrint("Testing abandon button...")
        UI:OnAbandonClick()
    end
    
    -- Test UI toggle
    C_Timer.After(1, function()
        self:UserPrint("Testing UI toggle...")
        UI:Hide()
        
        C_Timer.After(1, function()
            UI:Show()
            self:UserPrint("Tests completed! Timeline UI should be visible and functional.")
            Core.DebugInfo("Test sequence completed successfully - all test events executed")
        end)
    end)
end

-- Test GUI specifically
function Commands:TestTimer()
    self:UserPrint("=== Testing Timer ===")
    
    -- Force start tracking
    if Core then
        Core:StartKeyTracking(15, 1) -- Test key level 15
        self:UserPrint("Started test tracking - Key Level 15")
        
        if UI then
            UI:Show()
            self:UserPrint("UI shown")
        end
    else
        self:UserPrint("Core module not available!")
    end
end

function Commands:ToggleLuaErrors()
    -- Toggle Lua error display
    local currentValue = GetCVar("scriptErrors")
    self:UserPrint("Current scriptErrors value: " .. tostring(currentValue))
    
    if GetCVar("scriptErrors") == "1" then
        SetCVar("scriptErrors", "0")
        self:UserPrint("Lua errors: OFF")d
    else
        SetCVar("scriptErrors", "1")
        self:UserPrint("Lua errors: ON")
    end
    
    -- Also try to enable verbose error reporting
    SetCVar("scriptProfile", "1")
    self:UserPrint("Verbose error reporting enabled")
end

function Commands:DisableAddon()
    -- Temporarily disable the addon to test if it's causing errors
    self:UserPrint("Disabling addon temporarily...")
    if UI and UI.mainFrame then
        UI.mainFrame:Hide()
        self:UserPrint("UI hidden - check if errors stop")
    end
    if Core then
        Core:StopKeyTracking()
        self:UserPrint("Core tracking stopped")
    end
end

function Commands:TestGUI()
    if Core and Core.DebugInfo then
        Core.DebugInfo("TestGUI command executed")
    end
    
    self:UserPrint("=== Testing GUI Components ===")
    
    -- Debug UI module availability
    if Core and Core.DebugInfo then
        Core.DebugInfo("UI module available: %s", tostring(UI ~= nil))
        if UI then
            Core.DebugInfo("UI.Show available: %s", tostring(UI.Show ~= nil))
        end
    end
    
    -- Show UI
    self:UserPrint("Showing timeline UI...")
    if UI and UI.Show then
        UI:Show()
    else
        self:UserPrint("✗ UI module not available")
        if Core and Core.DebugInfo then
            Core.DebugInfo("UI module check: UI=%s, UI.Show=%s", tostring(UI), tostring(UI and UI.Show))
        end
        return
    end
    
    -- Test UI components
    C_Timer.After(0.5, function()
        self:UserPrint("Testing UI components...")
        
        -- Test timeline frame
        if UI.timelineFrame then
            self:UserPrint("Timeline frame found")
        else
            self:UserPrint("Timeline frame not found")
        end
        
        -- Test main frame
        if UI.mainFrame then
            self:UserPrint("Main frame found")
        else
            self:UserPrint("Main frame not found")
        end
        
        -- Test abandon button
        if UI.abandonButton then
            self:UserPrint("Abandon button found")
        else
            self:UserPrint("Abandon button not found")
        end
        
        -- Test UI interactions
        C_Timer.After(1, function()
            self:UserPrint("Testing UI interactions...")
            self:TestUIInteractions()
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
    self:UserPrint("/iskd force - Force UI visible (testing)")
    self:UserPrint("/iskd normal - Return to normal behavior")
    self:UserPrint("/iskd debug - Show UI debug information")
    self:UserPrint("/iskd status - Show current status")
    self:UserPrint("/iskd abandon - Abandon current key")
    self:UserPrint("/iskd reset - Reset timeline data")
    self:UserPrint("/iskd export - Export timeline data")
    self:UserPrint("/iskd test - Run test scenarios")
    self:UserPrint("/iskd start - Start timer manually")
    self:UserPrint("/iskd follower - Start follower dungeon test")
    self:UserPrint("/iskd restore - Restore previous run after reload")
    self:UserPrint("/iskd bosses - Show boss kill times")
    self:UserPrint("/iskd gui - Test GUI components")
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
    self:UserPrint("/iskd b - Show bosses")
    self:UserPrint("/iskd g - Test GUI")
    
    Core.DebugInfo("Help command executed - displayed all available commands and shortcuts")
end

-- Assign to namespace
ns.Commands = Commands