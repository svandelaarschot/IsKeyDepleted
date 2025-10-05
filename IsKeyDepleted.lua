--[[
================================================================================
IsKeyDepleted Main File
================================================================================
This is the main entry point for the IsKeyDepleted addon. It handles:
- Addon initialization and module loading
- Settings registration with WoW interface
- Event handling for addon loading

Author: Alvarín-Silvermoon
Version: 0.1
================================================================================
--]]

-- ============================================================================
-- INITIALIZATION & NAMESPACE SETUP
-- ============================================================================

-- Get addon name and namespace from WoW
local addonName, ns = ...

-- Create a shared global namespace
local sharedNamespace = _G[addonName] or {}
_G[addonName] = sharedNamespace

-- Make the shared namespace available to all modules
ns = sharedNamespace
IsKeyDepleted = sharedNamespace

-- Ensure the namespace is properly initialized
if not ns.Constants then ns.Constants = {} end
if not ns.Core then ns.Core = {} end
if not ns.Commands then ns.Commands = {} end
if not ns.Events then ns.Events = {} end
if not ns.UI then ns.UI = {} end
if not ns.Options then ns.Options = {} end
if not ns.Player then ns.Player = {} end

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

--[[
    Initialize all addon modules in the correct order
    This function loads all required modules and sets up the addon
--]]
function ns.Initialize()
    -- Debug: Print namespace contents
    print("|cff39FF14IsKeyDepleted|r: Namespace contents:")
    for k, v in pairs(ns) do
        print("|cff39FF14IsKeyDepleted|r:   " .. k .. " (" .. type(v) .. ")")
    end
    
    -- Check if all modules are available and have Initialize functions
    if not ns.Core or not ns.Core.Initialize then
        print("|cffFF0000IsKeyDepleted|r: ERROR - Core module not loaded!")
        return
    end
    
    if not ns.Events or not ns.Events.Initialize then
        print("|cffFF0000IsKeyDepleted|r: ERROR - Events module not loaded!")
        return
    end
    
    if not ns.UI or not ns.UI.Initialize then
        print("|cffFF0000IsKeyDepleted|r: ERROR - UI module not loaded!")
        return
    end
    
    if not ns.Options or not ns.Options.Initialize then
        print("|cffFF0000IsKeyDepleted|r: ERROR - Options module not loaded!")
        return
    end
    
    if not ns.Commands or not ns.Commands.Initialize then
        print("|cffFF0000IsKeyDepleted|r: ERROR - Commands module not loaded!")
        return
    end
    
    -- Initialize core functionality first
    ns.Core.Initialize()
    
    -- Initialize slash commands
    ns.Commands.Initialize()

    -- Initialize event handling
    ns.Events.Initialize()
    
    -- Initialize user interface
    ns.UI.Initialize()
    
    -- Initialize options/settings
    ns.Options.Initialize()
    
    -- Notify user of successful initialization
    ns.Core.DebugInfo("All modules initialized!")
    ns.Core.DebugInfo("Use /iskd to toggle the interface")
    ns.Core.DebugInfo("All modules initialized successfully")
end

--[[
    Register addon settings with WoW interface
    This function handles settings registration
--]]
function ns.RegisterSettings()
    if Settings then
        -- Delegate settings registration to Options module
        if ns.Options and ns.Options.RegisterSettings then
            ns.Options.RegisterSettings()
        end
    end
end

-- ============================================================================
-- PUBLIC API FUNCTIONS
-- ============================================================================

--[[
    Get addon information
    Returns basic addon metadata
--]]
function ns.GetInfo()
    return {
        name = "IsKeyDepleted",
        version = "0.1",
        author = "Alvarín-Silvermoon",
        description = "Interactive timeline for Mythic+ key tracking with death counting and timeability analysis"
    }
end

--[[
    Get current addon status
    Returns status information from all modules
--]]
function ns.GetStatus()
    local stats = ns.Core:GetTimelineStats()
    local eventStats = ns.Events:GetEventStats()
    
    return {
        core = stats,
        events = eventStats,
        ui = {
            isVisible = ns.UI.mainFrame and ns.UI.mainFrame:IsVisible() or false
        }
    }
end

--[[
    Test functions for development
--]]
function ns.TestDeath()
    ns.Events:TestDeath()
end

function ns.TestBossKill()
    ns.Events:TestBossKill()
end

function ns.TestStartKey()
    ns.Events:TestStartKey()
end

function ns.TestStopKey()
    ns.Events:TestStopKey()
end

--[[
    Export timeline data
    Returns current timeline data for analysis
--]]
function ns.ExportData()
    return ns.Core:ExportTimelineData()
end

--[[
    UI control functions
--]]
function ns.ToggleUI()
    ns.UI:Toggle()
end

function ns.ShowUI()
    ns.UI:Show()
end

function ns.HideUI()
    ns.UI:Hide()
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

--[[
    Main event handler for addon loading
    This frame listens for the ADDON_LOADED event and initializes the addon
--]]
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    -- Check if this is our addon being loaded
    if event == "ADDON_LOADED" and ... == addonName then
        -- Use a small delay to ensure all modules are loaded
        C_Timer.After(0.1, function()
            -- Initialize all modules
            ns.Initialize()
            
            -- Register settings with WoW interface
            ns.RegisterSettings()
        end)
    end
end)
