--[[
===============================================================================
Events.lua - IsKeyDepleted Addon Event Handling
===============================================================================
This module handles all WoW API events for the addon including:
- Challenge mode events (start, complete, reset)
- Player events (death, alive, zone changes)
- Encounter events (boss kills, encounters)
- Addon lifecycle events

Author: Alvarín-Silvermoon
Version: 0.1
===============================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Use shared namespace
ns = _G[addonName] or ns

-- Create events namespace
ns.Events = ns.Events or {}

-- Local reference for easier access
local Events = ns.Events

-- Import other modules from namespace
local Constants = ns.Constants
local Core = ns.Core
local UI = ns.UI

-- Event state
Events.isInitialized = false
Events.eventFrame = nil

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

--[[
    Initialize the event system
    Sets up event frame and registers all required events
--]]
function Events:Initialize()
    if self.isInitialized then
        return
    end
    
    self:CreateEventFrame()
    self:RegisterEvents()
    
    self.isInitialized = true
    if Core and Core.DebugInfo then
        Core.DebugInfo("Event system initialized")
    end
end

-- Create the event frame
function Events:CreateEventFrame()
    self.eventFrame = CreateFrame("Frame", "IsKeyDepletedEventFrame")
    self.eventFrame:RegisterEvent("ADDON_LOADED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    self.eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self.eventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
    self.eventFrame:RegisterEvent("PLAYER_DEAD")
    self.eventFrame:RegisterEvent("PLAYER_ALIVE")
    self.eventFrame:RegisterEvent("ENCOUNTER_START")
    self.eventFrame:RegisterEvent("ENCOUNTER_END")
    self.eventFrame:RegisterEvent("BOSS_KILL")
    
    self.eventFrame:SetScript("OnEvent", function(self, event, ...)
        Events:HandleEvent(event, ...)
    end)
end

-- Register all events
function Events:RegisterEvents()
    if self.eventFrame then
        -- Events are already registered in CreateEventFrame
        if Core and Core.DebugInfo then
            Core.DebugInfo("Events registered successfully")
        end
    end
end

-- Handle all events
function Events:HandleEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == addonName then
            self:OnAddonLoaded()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:OnPlayerEnteringWorld()
    elseif event == "CHALLENGE_MODE_START" then
        self:OnChallengeModeStart()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        self:OnChallengeModeCompleted()
    elseif event == "CHALLENGE_MODE_RESET" then
        self:OnChallengeModeReset()
    elseif event == "PLAYER_DEAD" then
        self:OnPlayerDead()
    elseif event == "PLAYER_ALIVE" then
        self:OnPlayerAlive()
    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID, groupSize = ...
        self:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...
        self:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    elseif event == "BOSS_KILL" then
        local bossName = ...
        self:OnBossKill(bossName)
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Addon loaded event
function Events:OnAddonLoaded()
    if Core and Core.DebugInfo then
        Core.DebugInfo("Addon loaded successfully")
    end
    -- Initialize other systems
    Core:Initialize()
    UI:Initialize()
end

-- Player entering world event
function Events:OnPlayerEnteringWorld()
    -- Check if we're in a challenge mode
    if C_ChallengeMode.IsChallengeModeActive() then
        self:OnChallengeModeStart()
    end
end

-- Challenge mode start event
function Events:OnChallengeModeStart()
    local keyLevel = C_ChallengeMode.GetActiveKeystoneLevel()
    local dungeonId = C_ChallengeMode.GetActiveKeystoneMapID()
    
    if keyLevel and dungeonId then
        Core:StartKeyTracking(keyLevel, dungeonId)
        UI:Show()
        if Core and Core.DebugInfo then
            Core.DebugInfo("Challenge mode started - Key Level %d", keyLevel)
        end
    end
end

-- Challenge mode completed event
function Events:OnChallengeModeCompleted()
    Core:StopKeyTracking("Completed successfully")
    UI:Hide()
    if Core and Core.DebugInfo then
        Core.DebugInfo("Challenge mode completed!")
    end
end

-- Challenge mode reset event
function Events:OnChallengeModeReset()
    Core:StopKeyTracking("Reset")
    UI:Hide()
    if Core and Core.DebugInfo then
        Core.DebugInfo("Challenge mode reset")
    end
end

-- Player death event
function Events:OnPlayerDead()
    -- Get death reason if possible
    local deathReason = "Unknown"
    
    -- Try to get more specific death information
    if UnitAffectingCombat("player") then
        deathReason = "Combat"
    else
        deathReason = "Environmental"
    end
    
    Core:AddDeath(deathReason)
    if Core and Core.DebugInfo then
        Core.DebugInfo("Player died - %s", deathReason)
    end
end

-- Player alive event
function Events:OnPlayerAlive()
    -- Player has been resurrected
    if Core and Core.DebugInfo then
        Core.DebugInfo("Player resurrected")
    end
end

-- Encounter start event
function Events:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    if encounterName then
        if Core and Core.DebugInfo then
            Core.DebugInfo("Encounter started - %s", encounterName)
        end
    end
end

-- Encounter end event
function Events:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if encounterName and success then
        Core:AddBossKill(encounterName)
        if Core and Core.DebugInfo then
            Core.DebugInfo("Boss defeated - %s", encounterName)
        end
    end
end

-- Boss kill event
function Events:OnBossKill(bossName)
    if bossName then
        Core:AddBossKill(bossName)
        if Core and Core.DebugInfo then
            Core.DebugInfo("Boss killed - %s", bossName)
        end
    end
end

-- Zone changed event
function Events:OnZoneChanged()
    -- Check if we're still in a challenge mode
    if not C_ChallengeMode.IsChallengeModeActive() then
        Core:StopKeyTracking("Left challenge mode")
        UI:Hide()
    end
end

-- Group roster update event
function Events:OnGroupRosterUpdate()
    -- Update group information if needed
    if Core and Core.DebugInfo then
        Core.DebugInfo("Group roster updated")
    end
end

-- ============================================================================
-- TEST FUNCTIONS
-- ============================================================================

-- Manual event triggers for testing
function Events:TestDeath()
    Core:AddDeath("Test death")
end

function Events:TestBossKill()
    Core:AddBossKill("Test Boss")
end

function Events:TestStartKey()
    Core:StartKeyTracking(15, 1234)
end

function Events:TestStopKey()
    Core:StopKeyTracking("Test stop")
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get event statistics
function Events:GetEventStats()
    return {
        isInitialized = self.isInitialized,
        eventsRegistered = self.eventFrame and self.eventFrame:GetNumEvents() or 0
    }
end

-- Assign to namespace
ns.Events = Events