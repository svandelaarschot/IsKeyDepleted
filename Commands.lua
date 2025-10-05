-- IsKeyDepleted Slash Commands
-- Command system for user interaction and addon control

local addonName = "IsKeyDepleted"
local Commands = {}

-- Import other modules from namespace
local addonName, ns = ...
local Constants = ns.Constants
local Core = ns.Core
local UI = ns.UI
local Events = ns.Events

-- Initialize the command system
function Commands:Initialize()
    self:RegisterSlashCommands()
    print("|cff39FF14IsKeyDepleted|r: Command system initialized")
end

-- Register slash commands
function Commands:RegisterSlashCommands()
    -- Main command
    SLASH_ISKEYDEPLETED1 = "/" .. Constants.COMMANDS.MAIN
    SLASH_ISKEYDEPLETED2 = "/iskd"
    SLASH_ISKEYDEPLETED3 = "/isk"
    
    SlashCmdList["ISKEYDEPLETED"] = function(msg)
        self:HandleCommand(msg)
    end
end

-- Handle slash commands
function Commands:HandleCommand(msg)
    local args = self:ParseCommand(msg)
    local command = args[1]:lower()
    
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
        print("|cff39FF14IsKeyDepleted|r: Unknown command. Use /iskd help for available commands.")
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
    print("|cff39FF14IsKeyDepleted|r: UI toggled")
end

-- Show UI
function Commands:ShowUI()
    UI:Show()
    print("|cff39FF14IsKeyDepleted|r: UI shown")
end

-- Hide UI
function Commands:HideUI()
    UI:Hide()
    print("|cff39FF14IsKeyDepleted|r: UI hidden")
end

-- Show status
function Commands:ShowStatus()
    local stats = Core:GetTimelineStats()
    local timelineData = Core:GetTimelineData()
    
    print("|cff39FF14IsKeyDepleted|r: === Status Report ===")
    print("|cff39FF14IsKeyDepleted|r: Timeability: " .. stats.timeabilityStatus)
    print("|cff39FF14IsKeyDepleted|r: Deaths: " .. stats.deathCount .. " (+" .. stats.deathPenalty .. "s penalty)")
    print("|cff39FF14IsKeyDepleted|r: Remaining Time: " .. Core:FormatTime(stats.remainingTime))
    print("|cff39FF14IsKeyDepleted|r: Progress: " .. math.floor(stats.progressPercentage * 100) .. "%")
    print("|cff39FF14IsKeyDepleted|r: Active: " .. (timelineData.isActive and "Yes" or "No"))
    
    if #timelineData.deaths > 0 then
        print("|cff39FF14IsKeyDepleted|r: Death History:")
        for i, death in ipairs(timelineData.deaths) do
            print("|cff39FF14IsKeyDepleted|r:   " .. i .. ". " .. Core:FormatTime(death.time) .. " - " .. death.reason)
        end
    end
    
    if #timelineData.bosses > 0 then
        print("|cff39FF14IsKeyDepleted|r: Bosses Killed:")
        for i, boss in ipairs(timelineData.bosses) do
            print("|cff39FF14IsKeyDepleted|r:   " .. i .. ". " .. boss.name .. " at " .. Core:FormatTime(boss.time))
        end
    end
end

-- Abandon key
function Commands:AbandonKey()
    if Core:ShouldShowAbandonButton() then
        Core:ExecuteAbandon()
        print("|cff39FF14IsKeyDepleted|r: Abandoning key...")
    else
        print("|cff39FF14IsKeyDepleted|r: Key is still timeable! Abandon button not available.")
    end
end

-- Reset timeline
function Commands:ResetTimeline()
    Core:ResetTimelineData()
    print("|cff39FF14IsKeyDepleted|r: Timeline reset")
end

-- Export data
function Commands:ExportData()
    local exportData = Core:ExportTimelineData()
    print("|cff39FF14IsKeyDepleted|r: === Export Data ===")
    print("|cff39FF14IsKeyDepleted|r: Version: " .. exportData.version)
    print("|cff39FF14IsKeyDepleted|r: Timestamp: " .. date("%Y-%m-%d %H:%M:%S", exportData.timestamp))
    
    if exportData.key then
        print("|cff39FF14IsKeyDepleted|r: Key Level: " .. exportData.key.level)
        print("|cff39FF14IsKeyDepleted|r: Dungeon ID: " .. exportData.key.dungeonId)
    end
    
    print("|cff39FF14IsKeyDepleted|r: Deaths: " .. #exportData.timeline.deaths)
    print("|cff39FF14IsKeyDepleted|r: Bosses: " .. #exportData.timeline.bosses)
    print("|cff39FF14IsKeyDepleted|r: Events: " .. #exportData.timeline.events)
end

-- Run tests
function Commands:RunTests()
    print("|cff39FF14IsKeyDepleted|r: === Running Tests ===")
    
    -- Test start key
    print("|cff39FF14IsKeyDepleted|r: Testing key start...")
    Events:TestStartKey()
    
    -- Wait a moment
    C_Timer.After(1, function()
        print("|cff39FF14IsKeyDepleted|r: Testing death...")
        Events:TestDeath()
        
        C_Timer.After(1, function()
            print("|cff39FF14IsKeyDepleted|r: Testing boss kill...")
            Events:TestBossKill()
            
            C_Timer.After(1, function()
                print("|cff39FF14IsKeyDepleted|r: Testing key stop...")
                Events:TestStopKey()
                print("|cff39FF14IsKeyDepleted|r: Tests completed!")
            end)
        end)
    end)
end

-- Toggle Blizzard tracker
function Commands:ToggleBlizzardTracker()
    UI:ToggleBlizzardTracker()
    local status = UI:IsBlizzardTrackerHidden() and "hidden" or "shown"
    print("|cff39FF14IsKeyDepleted|r: Blizzard tracker " .. status)
end

-- Show help
function Commands:ShowHelp()
    print("|cff39FF14IsKeyDepleted|r: === Available Commands ===")
    print("|cff39FF14IsKeyDepleted|r: /iskd toggle - Toggle the UI")
    print("|cff39FF14IsKeyDepleted|r: /iskd show - Show the UI")
    print("|cff39FF14IsKeyDepleted|r: /iskd hide - Hide the UI")
    print("|cff39FF14IsKeyDepleted|r: /iskd status - Show current status")
    print("|cff39FF14IsKeyDepleted|r: /iskd abandon - Abandon current key")
    print("|cff39FF14IsKeyDepleted|r: /iskd reset - Reset timeline data")
    print("|cff39FF14IsKeyDepleted|r: /iskd export - Export timeline data")
    print("|cff39FF14IsKeyDepleted|r: /iskd test - Run test scenarios")
    print("|cff39FF14IsKeyDepleted|r: /iskd tracker - Toggle Blizzard tracker")
    print("|cff39FF14IsKeyDepleted|r: /iskd help - Show this help")
    print("|cff39FF14IsKeyDepleted|r: === Shortcuts ===")
    print("|cff39FF14IsKeyDepleted|r: /iskd t - Toggle UI")
    print("|cff39FF14IsKeyDepleted|r: /iskd s - Show UI")
    print("|cff39FF14IsKeyDepleted|r: /iskd h - Hide UI")
    print("|cff39FF14IsKeyDepleted|r: /iskd stat - Show status")
    print("|cff39FF14IsKeyDepleted|r: /iskd a - Abandon key")
    print("|cff39FF14IsKeyDepleted|r: /iskd r - Reset timeline")
    print("|cff39FF14IsKeyDepleted|r: /iskd e - Export data")
end

-- Make Commands available in namespace
local addonName, ns = ...
ns.Commands = Commands

return Commands
