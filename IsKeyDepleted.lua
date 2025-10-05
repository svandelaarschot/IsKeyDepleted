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

-- Create global namespace for external access
IsKeyDepleted = ns

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

--[[
    Initialize all addon modules in the correct order
    This function loads all required modules and sets up the addon
--]]
function ns.Initialize()
    -- Initialize core functionality first
    ns.Core:Initialize()
    
    -- Initialize player data
    ns.Player:Initialize()
    
    -- Initialize event handling
    ns.Events:Initialize()
    
    -- Initialize user interface
    ns.UI:Initialize()
    
    -- Initialize options/settings
    ns.Options:Initialize()
    
    -- Initialize slash commands
    ns.Commands:Initialize()
    
    -- Notify user of successful initialization
    print("|cff39FF14IsKeyDepleted|r: All modules initialized!")
    print("|cff39FF14IsKeyDepleted|r: Use /iskd to toggle the interface")
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
        -- Initialize all modules
        ns.Initialize()
        
        -- Register settings with WoW interface
        ns.RegisterSettings()
    end
end)
