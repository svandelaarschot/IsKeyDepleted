--[[
================================================================================
Player.lua - IsKeyDepleted Addon Player Module
================================================================================
This module handles player-specific data and interactions including:
- Player data management
- Key tracking and monitoring
- Death counting and penalty calculations
- Timer monitoring and updates
- Timeline data storage and retrieval

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

-- Create player namespace
ns.Player = ns.Player or {}

-- Local reference for easier access
local Player = ns.Player

-- Import other modules from namespace
local Constants = ns.Constants
local Core = ns.Core

-- ============================================================================
-- PLAYER STATE AND VARIABLES
-- ============================================================================

-- Player state
Player.isInitialized = false
Player.currentPlayer = nil
Player.playerData = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
    Initialize player module
    Sets up player tracking and data management
--]]
function Player:Initialize()
    if self.isInitialized then
        return
    end
    
    self:InitializePlayerData()
    self.isInitialized = true
    
    if Core and Core.DebugInfo then
        Core.DebugInfo("Player module initialized")
    end
end

--[[
    Initialize player data
    Sets up default player data structure
--]]
function Player:InitializePlayerData()
    self.playerData = {
        name = UnitName("player"),
        realm = GetRealmName(),
        class = UnitClass("player"),
        level = UnitLevel("player"),
        currentKey = nil,
        isInMythicPlus = false,
        deaths = 0,
        startTime = 0
    }
end

-- ============================================================================
-- PLAYER DATA FUNCTIONS
-- ============================================================================

--[[
    Get current player data
    Returns the current player information
--]]
function Player:GetPlayerData()
    return self.playerData
end

--[[
    Update player data
    Refreshes player information
--]]
function Player:UpdatePlayerData()
    self.playerData.name = UnitName("player")
    self.playerData.realm = GetRealmName()
    self.playerData.class = UnitClass("player")
    self.playerData.level = UnitLevel("player")
end

--[[
    Check if player is in Mythic+
    Returns true if currently in a Mythic+ dungeon
--]]
function Player:IsInMythicPlus()
    return self.playerData.isInMythicPlus
end

--[[
    Set Mythic+ status
    Updates the Mythic+ participation status
--]]
function Player:SetMythicPlusStatus(isInMythicPlus)
    self.playerData.isInMythicPlus = isInMythicPlus
end

--[[
    Get current key information
    Returns the current Mythic+ key data
--]]
function Player:GetCurrentKey()
    return self.playerData.currentKey
end

--[[
    Set current key
    Updates the current Mythic+ key information
--]]
function Player:SetCurrentKey(keyData)
    self.playerData.currentKey = keyData
end

--[[
    Get death count
    Returns the current death count for this player
--]]
function Player:GetDeathCount()
    return self.playerData.deaths
end

--[[
    Add death
    Increments the death count
--]]
function Player:AddDeath()
    self.playerData.deaths = self.playerData.deaths + 1
end

--[[
    Reset death count
    Resets the death count to zero
--]]
function Player:ResetDeaths()
    self.playerData.deaths = 0
end

--[[
    Get start time
    Returns when the current run started
--]]
function Player:GetStartTime()
    return self.playerData.startTime
end

--[[
    Set start time
    Updates the start time for the current run
--]]
function Player:SetStartTime(time)
    self.playerData.startTime = time
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--[[
    Get player name
    Returns the current player's name
--]]
function Player:GetPlayerName()
    return self.playerData.name
end

--[[
    Get player realm
    Returns the current player's realm
--]]
function Player:GetPlayerRealm()
    return self.playerData.realm
end

--[[
    Get player class
    Returns the current player's class
--]]
function Player:GetPlayerClass()
    return self.playerData.class
end

--[[
    Get player level
    Returns the current player's level
--]]
function Player:GetPlayerLevel()
    return self.playerData.level
end

--[[
    Reset player data
    Resets all player data to default values
--]]
function Player:ResetPlayerData()
    self:InitializePlayerData()
end

-- Assign to namespace
ns.Player = Player
