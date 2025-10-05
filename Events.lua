-- IsKeyDepleted Event Handling
-- Event system for tracking key status, deaths, and timeline events

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

-- Initialize the event system
function Events:Initialize()
    if self.isInitialized then
        return
    end
    
    self:CreateEventFrame()
    self:RegisterEvents()
    
    self.isInitialized = true
    Core.DebugInfo("Event system initialized")
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
    self.eventFrame:RegisterEvent("UNIT_DIED")
    
    self.eventFrame:SetScript("OnEvent", function(self, event, ...)
        Events:HandleEvent(event, ...)
    end)
end

-- Register additional events
function Events:RegisterEvents()
    -- Register for challenge mode events
    self.eventFrame:RegisterEvent("CHALLENGE_MODE_LEADERS_UPDATE")
    self.eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
    
    -- Register for combat events
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    -- Register for zone changes
    self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.eventFrame:RegisterEvent("ZONE_CHANGED")
    
    -- Register for group events
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
    self.eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")
end

-- Handle incoming events
function Events:HandleEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == Constants.ADDON_NAME then
            self:OnAddonLoaded()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:OnPlayerEnteringWorld()
    elseif event == "CHALLENGE_MODE_START" then
        self:OnChallengeModeStart(...)
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        self:OnChallengeModeCompleted(...)
    elseif event == "CHALLENGE_MODE_RESET" then
        self:OnChallengeModeReset(...)
    elseif event == "PLAYER_DEAD" then
        self:OnPlayerDead(...)
    elseif event == "PLAYER_ALIVE" then
        self:OnPlayerAlive(...)
    elseif event == "ENCOUNTER_START" then
        self:OnEncounterStart(...)
    elseif event == "ENCOUNTER_END" then
        self:OnEncounterEnd(...)
    elseif event == "BOSS_KILL" then
        self:OnBossKill(...)
    elseif event == "UNIT_DIED" then
        self:OnUnitDied(...)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        self:OnZoneChanged()
    elseif event == "GROUP_ROSTER_UPDATE" then
        self:OnGroupRosterUpdate()
    end
end

-- Addon loaded event
function Events:OnAddonLoaded()
    Core.DebugInfo("Addon loaded successfully")
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
        Core.DebugInfo("Challenge mode started - Key Level %d", keyLevel)
    end
end

-- Challenge mode completed event
function Events:OnChallengeModeCompleted()
    Core:StopKeyTracking("Completed successfully")
    Core.DebugInfo("Challenge mode completed!")
end

-- Challenge mode reset event
function Events:OnChallengeModeReset()
    Core:StopKeyTracking("Reset")
    Core.DebugInfo("Challenge mode reset")
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
    Core.DebugInfo("Player died - %s", deathReason)
end

-- Player alive event
function Events:OnPlayerAlive()
    -- Player has been resurrected
    Core.DebugInfo("Player resurrected")
end

-- Encounter start event
function Events:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    if encounterName then
        Core.DebugInfo("Encounter started - %s", encounterName)
    end
end

-- Encounter end event
function Events:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if encounterName and success then
        Core:AddBossKill(encounterName)
        Core.DebugInfo("Boss defeated - %s", encounterName)
    end
end

-- Boss kill event
function Events:OnBossKill(bossName)
    if bossName then
        Core:AddBossKill(bossName)
        Core.DebugInfo("Boss killed - %s", bossName)
    end
end

-- Unit died event
function Events:OnUnitDied(unitID)
    -- Check if it's a party member
    if unitID and (unitID:find("party") or unitID:find("raid")) then
        local unitName = UnitName(unitID)
        if unitName then
            Core.DebugInfo("Party member died - %s", unitName)
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
    Core.DebugInfo("Group roster updated")
end

-- Manual event triggers for testing
function Events:TestDeath()
    Core:AddDeath("Test death")
end

function Events:TestBossKill()
    Core:AddBossKill("Test Boss")
end

function Events:TestStartKey()
    Core:StartKeyTracking(15, 123) -- Test with level 15 key
    UI:Show()
end

function Events:TestStopKey()
    Core:StopKeyTracking("Test stop")
end

-- Get event statistics
function Events:GetEventStats()
    return {
        isInitialized = self.isInitialized,
        eventsRegistered = self.eventFrame and self.eventFrame:GetNumEvents() or 0
    }
end

-- Assign to namespace
ns.Events = Events
