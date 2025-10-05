--[[
================================================================================
Options.lua - IsKeyDepleted Addon Settings Management
================================================================================
This module handles all addon settings and configuration options including:
- Settings initialization and defaults
- Options panel creation with submenus
- Settings persistence and retrieval
- UI for all configuration options

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

-- Create options namespace
ns.Options = ns.Options or {}

-- ============================================================================
-- DEFAULT CONFIGURATION
-- ============================================================================

--[[
    Default options configuration
    These values are used when the addon is first loaded or when options are missing
--]]
local defaultOptions = {
    -- Timeline Settings
    hideBlizzardTracker = true,       -- Hide default Blizzard dungeon tracker
    deathPenaltySeconds = 5,         -- Death penalty time in seconds
    autoShowTimeline = true,         -- Auto-show timeline when entering Mythic+
    
    -- Timeability Settings
    timeabilityThresholds = {
        timeable = 0.8,              -- 80% of time remaining
        borderline = 0.6,             -- 60% of time remaining
        notTimeable = 0.4            -- 40% of time remaining
    },
    
    -- Display Settings
    timelineWidth = 400,             -- Timeline width in pixels
    timelineHeight = 60,             -- Timeline height in pixels
    showDeathMarkers = true,         -- Show death markers on timeline
    showBossMarkers = true,          -- Show boss kill markers on timeline
    showTimeLabels = true,           -- Show time labels on timeline
    
    -- Abandon Button Settings
    showAbandonButton = true,        -- Show abandon button when not timeable
    abandonConfirmation = true,      -- Show confirmation dialog for abandon
    
    -- Debug Settings
    debugMode = false,               -- Enable debug output
    debugLevel = 3,                 -- Debug level (1=ERROR, 2=WARNING, 3=INFO, 4=DEBUG, 5=VERBOSE)
}

-- ============================================================================
-- CORE OPTIONS FUNCTIONS
-- ============================================================================

--[[
    Create a footer for settings panels
    @param panel (Frame) - The panel to add the footer to
--]]
function ns.Options.CreateFooter(panel)
    local footer = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOMLEFT", 16, 16)
    footer:SetWidth(580)
    footer:SetJustifyH("LEFT")
    
    -- Get dynamic version from .toc file with fallback
    local version = "0.1"
    local author = "Alvarín-Silvermoon"
    
    -- Try to get metadata, but use fallbacks if it fails
    if GetAddOnMetadata then
        local addonName = "IsKeyDepleted"
        local metadataVersion = GetAddOnMetadata(addonName, "Version")
        local metadataAuthor = GetAddOnMetadata(addonName, "Author")
        
        if metadataVersion then
            version = metadataVersion
        end
        if metadataAuthor then
            author = metadataAuthor
        end
    end
    
    footer:SetText("|cff39FF14IsKeyDepleted|r - Interactive Mythic+ Timeline | Version " .. version .. " | by " .. author .. " | Use /iskd help for commands")
    footer:SetTextColor(0.7, 0.7, 0.7)
end

--[[
    Initialize options with default values if they don't exist
    This ensures all options are properly set when the addon loads
--]]
function ns.Options.InitializeOptions()
    if not IsKeyDepletedDB.options then
        IsKeyDepletedDB.options = {}
    end
    
    -- Set default values for any missing options
    for key, defaultValue in pairs(defaultOptions) do
        if IsKeyDepletedDB.options[key] == nil then
            IsKeyDepletedDB.options[key] = defaultValue
        end
    end
end

--[[
    Initialize options system
    Sets up default options if they don't exist in the saved variables
--]]
function ns.Options.Initialize()
    -- Create options table if it doesn't exist
    if not IsKeyDepletedDB.options then
        IsKeyDepletedDB.options = {}
    end
    
    -- Set default values for any missing options
    for key, value in pairs(defaultOptions) do
        if IsKeyDepletedDB.options[key] == nil then
            IsKeyDepletedDB.options[key] = value
        end
    end
    
    ns.Core.DebugInfo("Options initialized!")
end

--[[
    Set an option value
    @param key (string) - The option key to set
    @param value (any) - The value to set
--]]
function ns.Options.SetOption(key, value)
    -- Ensure options table exists
    if IsKeyDepletedDB.options then
        IsKeyDepletedDB.options[key] = value
    end
end

--[[
    Get an option value
    @param key (string) - The option key to retrieve
    @return (any) - The option value or default if not set
--]]
function ns.Options.GetOption(key)
    -- Return saved value if it exists
    if IsKeyDepletedDB.options then
        return IsKeyDepletedDB.options[key]
    end
    -- Return default value
    return defaultOptions[key]
end

-- ============================================================================
-- SETTINGS REGISTRATION
-- ============================================================================

--[[
    Register settings with WoW interface
    Creates the main settings panel and registers it with WoW's settings system
--]]
function ns.Options.RegisterSettings()
    if Settings then
        -- Initialize options with default values
        ns.Options.InitializeOptions()
        
        -- Create root panel
        local rootPanel = CreateFrame("Frame", "IsKeyDepletedRootPanel")
        rootPanel.name = "IsKeyDepleted"
        
        -- Title
        local titleRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleRoot:SetPoint("TOPLEFT", 16, -16)
        titleRoot:SetText("|cff39FF14IsKeyDepleted|r - Settings")
        
        -- Description
        local descRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        descRoot:SetPoint("TOPLEFT", titleRoot, "BOTTOMLEFT", 0, -8)
        descRoot:SetWidth(580)
        descRoot:SetJustifyH("LEFT")
        descRoot:SetText("Interactive timeline for Mythic+ key tracking with death counting and timeability analysis.")
        
        -- Usage guide
        local usageGuide = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        usageGuide:SetPoint("TOPLEFT", descRoot, "BOTTOMLEFT", 0, -15)
        usageGuide:SetWidth(580)
        usageGuide:SetJustifyH("LEFT")
        usageGuide:SetText("|cffFFD700Quick Start:|r\n" ..
                          "1. Enter a Mythic+ dungeon to start tracking\n" ..
                          "2. Watch the interactive timeline for progress\n" ..
                          "3. Monitor deaths and timeability status\n" ..
                          "4. Use abandon button when key is not timeable\n\n" ..
                          "|cffFFD700Main Commands:|r\n" ..
                          "• /iskd - Toggle the timeline interface\n" ..
                          "• /iskd status - Show current status\n" ..
                          "• /iskd abandon - Abandon current key\n" ..
                          "• /iskd test - Run test scenarios\n" ..
                          "• /iskd help - Show all commands")
        usageGuide:SetTextColor(0.9, 0.9, 0.9)
        
        -- Add footer to main panel
        ns.Options.CreateFooter(rootPanel)
        
        -- Create subpanels (placeholders for now)
        local timelinePanel = ns.Options.CreateTimelinePanel()
        local displayPanel = ns.Options.CreateDisplayPanel()
        local abandonPanel = ns.Options.CreateAbandonPanel()
        local debugPanel = ns.Options.CreateDebugPanel()
        
        -- Register as addon category with subpanels
        local root = Settings.RegisterCanvasLayoutCategory(rootPanel, rootPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, timelinePanel, timelinePanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, displayPanel, displayPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, abandonPanel, abandonPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, debugPanel, debugPanel.name)
        Settings.RegisterAddOnCategory(root)
        
        ns.Core.DebugInfo("Settings registered with WoW interface")
    end
end

-- ============================================================================
-- UI PANEL CREATION (PLACEHOLDERS)
-- ============================================================================

--[[
    Create Timeline Settings Panel
--]]
function ns.Options.CreateTimelinePanel()
    local panel = CreateFrame("Frame", "IsKeyDepletedTimelinePanel")
    panel.name = "Timeline"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14IsKeyDepleted|r - Timeline Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure timeline behavior, tracking settings, and timeability thresholds.")
    
    local yOffset = -60
    
    -- Auto-show timeline checkbox
    local autoShowCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    autoShowCheck:SetPoint("TOPLEFT", 20, yOffset)
    autoShowCheck.Text:SetText("Auto-show timeline when entering Mythic+")
    autoShowCheck:SetChecked(IsKeyDepletedDB.options and IsKeyDepletedDB.options.autoShowTimeline or true)
    autoShowCheck:SetScript("OnClick", function(self)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.autoShowTimeline = self:GetChecked()
    end)
    
    -- Auto-show description
    local autoShowDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoShowDesc:SetPoint("TOPLEFT", autoShowCheck, "BOTTOMLEFT", 20, -5)
    autoShowDesc:SetWidth(540)
    autoShowDesc:SetJustifyH("LEFT")
    autoShowDesc:SetText("Automatically shows the timeline interface when entering a Mythic+ dungeon.")
    autoShowDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 80
    
    -- Death penalty time slider
    local deathPenaltyLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathPenaltyLabel:SetPoint("TOPLEFT", 20, yOffset)
    deathPenaltyLabel:SetText("Death penalty time (seconds):")
    
    local deathPenaltySlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    deathPenaltySlider:SetPoint("TOPLEFT", deathPenaltyLabel, "BOTTOMLEFT", 0, -10)
    deathPenaltySlider:SetSize(300, 20)
    deathPenaltySlider:SetMinMaxValues(1, 10)
    deathPenaltySlider:SetValue(IsKeyDepletedDB.options and IsKeyDepletedDB.options.deathPenaltySeconds or 5)
    deathPenaltySlider:SetValueStep(1)
    deathPenaltySlider:SetObeyStepOnDrag(true)
    deathPenaltySlider.Low:SetText("1s")
    deathPenaltySlider.High:SetText("10s")
    
    local deathPenaltyValue = deathPenaltySlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathPenaltyValue:SetPoint("LEFT", deathPenaltySlider, "RIGHT", 15, 0)
    deathPenaltyValue:SetText(tostring(IsKeyDepletedDB.options and IsKeyDepletedDB.options.deathPenaltySeconds or 5) .. "s")
    
    deathPenaltySlider:SetScript("OnValueChanged", function(self, value)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.deathPenaltySeconds = value
        deathPenaltyValue:SetText(tostring(value) .. "s")
    end)
    
    -- Death penalty description
    local deathPenaltyDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    deathPenaltyDesc:SetPoint("TOPLEFT", deathPenaltySlider, "BOTTOMLEFT", 0, -5)
    deathPenaltyDesc:SetWidth(540)
    deathPenaltyDesc:SetJustifyH("LEFT")
    deathPenaltyDesc:SetText("Time penalty added to the timer for each death. Standard is 5 seconds per death.")
    deathPenaltyDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 100
    
    -- Timeability Thresholds Section
    local thresholdsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    thresholdsLabel:SetPoint("TOPLEFT", 20, yOffset)
    thresholdsLabel:SetText("Timeability Thresholds:")
    thresholdsLabel:SetTextColor(1, 1, 0.5)
    
    local thresholdsDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    thresholdsDesc:SetPoint("TOPLEFT", thresholdsLabel, "BOTTOMLEFT", 0, -5)
    thresholdsDesc:SetWidth(540)
    thresholdsDesc:SetJustifyH("LEFT")
    thresholdsDesc:SetText("Configure when the key is considered timeable, borderline, or not timeable based on remaining time percentage.")
    thresholdsDesc:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 50
    
    -- Timeable threshold
    local timeableLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeableLabel:SetPoint("TOPLEFT", 40, yOffset)
    timeableLabel:SetText("Timeable threshold (%):")
    
    local timeableSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    timeableSlider:SetPoint("TOPLEFT", timeableLabel, "BOTTOMLEFT", 0, -10)
    timeableSlider:SetSize(250, 20)
    timeableSlider:SetMinMaxValues(0.5, 1.0)
    timeableSlider:SetValue(IsKeyDepletedDB.options and IsKeyDepletedDB.options.timeabilityThresholds and IsKeyDepletedDB.options.timeabilityThresholds.timeable or 0.8)
    timeableSlider:SetValueStep(0.05)
    timeableSlider:SetObeyStepOnDrag(true)
    timeableSlider.Low:SetText("50%")
    timeableSlider.High:SetText("100%")
    
    local timeableValue = timeableSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeableValue:SetPoint("LEFT", timeableSlider, "RIGHT", 15, 0)
    local timeableVal = IsKeyDepletedDB.options and IsKeyDepletedDB.options.timeabilityThresholds and IsKeyDepletedDB.options.timeabilityThresholds.timeable or 0.8
    timeableValue:SetText(tostring(math.floor(timeableVal * 100)) .. "%")
    
    timeableSlider:SetScript("OnValueChanged", function(self, value)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        if not IsKeyDepletedDB.options.timeabilityThresholds then IsKeyDepletedDB.options.timeabilityThresholds = {} end
        IsKeyDepletedDB.options.timeabilityThresholds.timeable = value
        timeableValue:SetText(tostring(math.floor(value * 100)) .. "%")
    end)
    
    yOffset = yOffset - 60
    
    -- Borderline threshold
    local borderlineLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    borderlineLabel:SetPoint("TOPLEFT", 40, yOffset)
    borderlineLabel:SetText("Borderline threshold (%):")
    
    local borderlineSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    borderlineSlider:SetPoint("TOPLEFT", borderlineLabel, "BOTTOMLEFT", 0, -10)
    borderlineSlider:SetSize(250, 20)
    borderlineSlider:SetMinMaxValues(0.3, 0.9)
    borderlineSlider:SetValue(IsKeyDepletedDB.options and IsKeyDepletedDB.options.timeabilityThresholds and IsKeyDepletedDB.options.timeabilityThresholds.borderline or 0.6)
    borderlineSlider:SetValueStep(0.05)
    borderlineSlider:SetObeyStepOnDrag(true)
    borderlineSlider.Low:SetText("30%")
    borderlineSlider.High:SetText("90%")
    
    local borderlineValue = borderlineSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    borderlineValue:SetPoint("LEFT", borderlineSlider, "RIGHT", 15, 0)
    local borderlineVal = IsKeyDepletedDB.options and IsKeyDepletedDB.options.timeabilityThresholds and IsKeyDepletedDB.options.timeabilityThresholds.borderline or 0.6
    borderlineValue:SetText(tostring(math.floor(borderlineVal * 100)) .. "%")
    
    borderlineSlider:SetScript("OnValueChanged", function(self, value)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        if not IsKeyDepletedDB.options.timeabilityThresholds then IsKeyDepletedDB.options.timeabilityThresholds = {} end
        IsKeyDepletedDB.options.timeabilityThresholds.borderline = value
        borderlineValue:SetText(tostring(math.floor(value * 100)) .. "%")
    end)
    
    -- Add footer
    ns.Options.CreateFooter(panel)
    
    return panel
end

--[[
    Create Display Settings Panel
--]]
function ns.Options.CreateDisplayPanel()
    local panel = CreateFrame("Frame", "IsKeyDepletedDisplayPanel")
    panel.name = "Display"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14IsKeyDepleted|r - Display Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure display and visual settings for the timeline interface.")
    
    local yOffset = -60
    
    -- Hide Blizzard tracker checkbox
    local hideBlizzardCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    hideBlizzardCheck:SetPoint("TOPLEFT", 20, yOffset)
    hideBlizzardCheck.Text:SetText("Hide default Blizzard dungeon tracker")
    hideBlizzardCheck:SetChecked(IsKeyDepletedDB.options and IsKeyDepletedDB.options.hideBlizzardTracker or true)
    hideBlizzardCheck:SetScript("OnClick", function(self)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.hideBlizzardTracker = self:GetChecked()
    end)
    
    -- Hide Blizzard description
    local hideBlizzardDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hideBlizzardDesc:SetPoint("TOPLEFT", hideBlizzardCheck, "BOTTOMLEFT", 20, -5)
    hideBlizzardDesc:SetWidth(540)
    hideBlizzardDesc:SetJustifyH("LEFT")
    hideBlizzardDesc:SetText("Hides the default Blizzard dungeon tracker to prevent UI clutter. Recommended for cleaner interface.")
    hideBlizzardDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 80
    
    -- Timeline size section
    local sizeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", 20, yOffset)
    sizeLabel:SetText("Timeline Size:")
    sizeLabel:SetTextColor(1, 1, 0.5)
    
    local sizeDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sizeDesc:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -5)
    sizeDesc:SetWidth(540)
    sizeDesc:SetJustifyH("LEFT")
    sizeDesc:SetText("Adjust the size of the interactive timeline interface.")
    sizeDesc:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 50
    
    -- Timeline width
    local widthLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widthLabel:SetPoint("TOPLEFT", 40, yOffset)
    widthLabel:SetText("Timeline width (pixels):")
    
    local widthSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", widthLabel, "BOTTOMLEFT", 0, -10)
    widthSlider:SetSize(250, 20)
    widthSlider:SetMinMaxValues(300, 600)
    widthSlider:SetValue(IsKeyDepletedDB.options and IsKeyDepletedDB.options.timelineWidth or 400)
    widthSlider:SetValueStep(25)
    widthSlider:SetObeyStepOnDrag(true)
    widthSlider.Low:SetText("300px")
    widthSlider.High:SetText("600px")
    
    local widthValue = widthSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widthValue:SetPoint("LEFT", widthSlider, "RIGHT", 15, 0)
    widthValue:SetText(tostring(IsKeyDepletedDB.options and IsKeyDepletedDB.options.timelineWidth or 400) .. "px")
    
    widthSlider:SetScript("OnValueChanged", function(self, value)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.timelineWidth = value
        widthValue:SetText(tostring(value) .. "px")
    end)
    
    yOffset = yOffset - 60
    
    -- Timeline height
    local heightLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heightLabel:SetPoint("TOPLEFT", 40, yOffset)
    heightLabel:SetText("Timeline height (pixels):")
    
    local heightSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", heightLabel, "BOTTOMLEFT", 0, -10)
    heightSlider:SetSize(250, 20)
    heightSlider:SetMinMaxValues(40, 120)
    heightSlider:SetValue(IsKeyDepletedDB.options and IsKeyDepletedDB.options.timelineHeight or 60)
    heightSlider:SetValueStep(10)
    heightSlider:SetObeyStepOnDrag(true)
    heightSlider.Low:SetText("40px")
    heightSlider.High:SetText("120px")
    
    local heightValue = heightSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heightValue:SetPoint("LEFT", heightSlider, "RIGHT", 15, 0)
    heightValue:SetText(tostring(IsKeyDepletedDB.options and IsKeyDepletedDB.options.timelineHeight or 60) .. "px")
    
    heightSlider:SetScript("OnValueChanged", function(self, value)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.timelineHeight = value
        heightValue:SetText(tostring(value) .. "px")
    end)
    
    yOffset = yOffset - 100
    
    -- Timeline markers section
    local markersLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    markersLabel:SetPoint("TOPLEFT", 20, yOffset)
    markersLabel:SetText("Timeline Markers:")
    markersLabel:SetTextColor(1, 1, 0.5)
    
    local markersDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    markersDesc:SetPoint("TOPLEFT", markersLabel, "BOTTOMLEFT", 0, -5)
    markersDesc:SetWidth(540)
    markersDesc:SetJustifyH("LEFT")
    markersDesc:SetText("Configure which markers to display on the timeline.")
    markersDesc:SetTextColor(0.8, 0.8, 0.8)
    
    yOffset = yOffset - 50
    
    -- Show death markers checkbox
    local deathMarkersCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    deathMarkersCheck:SetPoint("TOPLEFT", 40, yOffset)
    deathMarkersCheck.Text:SetText("Show death markers")
    deathMarkersCheck:SetChecked(IsKeyDepletedDB.options and IsKeyDepletedDB.options.showDeathMarkers or true)
    deathMarkersCheck:SetScript("OnClick", function(self)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.showDeathMarkers = self:GetChecked()
    end)
    
    -- Death markers description
    local deathMarkersDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    deathMarkersDesc:SetPoint("TOPLEFT", deathMarkersCheck, "BOTTOMLEFT", 20, -5)
    deathMarkersDesc:SetWidth(500)
    deathMarkersDesc:SetJustifyH("LEFT")
    deathMarkersDesc:SetText("Shows red markers on the timeline indicating when deaths occurred.")
    deathMarkersDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 60
    
    -- Show boss markers checkbox
    local bossMarkersCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    bossMarkersCheck:SetPoint("TOPLEFT", 40, yOffset)
    bossMarkersCheck.Text:SetText("Show boss kill markers")
    bossMarkersCheck:SetChecked(IsKeyDepletedDB.options and IsKeyDepletedDB.options.showBossMarkers or true)
    bossMarkersCheck:SetScript("OnClick", function(self)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.showBossMarkers = self:GetChecked()
    end)
    
    -- Boss markers description
    local bossMarkersDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bossMarkersDesc:SetPoint("TOPLEFT", bossMarkersCheck, "BOTTOMLEFT", 20, -5)
    bossMarkersDesc:SetWidth(500)
    bossMarkersDesc:SetJustifyH("LEFT")
    bossMarkersDesc:SetText("Shows green markers on the timeline indicating when bosses were killed.")
    bossMarkersDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 60
    
    -- Show time labels checkbox
    local timeLabelsCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    timeLabelsCheck:SetPoint("TOPLEFT", 40, yOffset)
    timeLabelsCheck.Text:SetText("Show time labels")
    timeLabelsCheck:SetChecked(IsKeyDepletedDB.options and IsKeyDepletedDB.options.showTimeLabels or true)
    timeLabelsCheck:SetScript("OnClick", function(self)
        if not IsKeyDepletedDB.options then IsKeyDepletedDB.options = {} end
        IsKeyDepletedDB.options.showTimeLabels = self:GetChecked()
    end)
    
    -- Time labels description
    local timeLabelsDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeLabelsDesc:SetPoint("TOPLEFT", timeLabelsCheck, "BOTTOMLEFT", 20, -5)
    timeLabelsDesc:SetWidth(500)
    timeLabelsDesc:SetJustifyH("LEFT")
    timeLabelsDesc:SetText("Shows time labels along the timeline for reference.")
    timeLabelsDesc:SetTextColor(0.7, 0.7, 0.7)
    
    -- Add footer
    ns.Options.CreateFooter(panel)
    
    return panel
end

--[[
    Create Abandon Settings Panel (Placeholder)
--]]
function ns.Options.CreateAbandonPanel()
    local panel = CreateFrame("Frame", "IsKeyDepletedAbandonPanel")
    panel.name = "Abandon"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14IsKeyDepleted|r - Abandon Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure abandon button behavior and confirmation settings.")
    
    -- Placeholder text
    local placeholder = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    placeholder:SetWidth(580)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetText("Abandon settings panel - Coming soon!")
    placeholder:SetTextColor(0.7, 0.7, 0.7)
    
    -- Add footer
    ns.Options.CreateFooter(panel)
    
    return panel
end

--[[
    Create Debug Settings Panel (Placeholder)
--]]
function ns.Options.CreateDebugPanel()
    local panel = CreateFrame("Frame", "IsKeyDepletedDebugPanel")
    panel.name = "Debug"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14IsKeyDepleted|r - Debug Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure debug mode and logging levels for troubleshooting addon issues.")
    
    -- Placeholder text
    local placeholder = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    placeholder:SetWidth(580)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetText("Debug settings panel - Coming soon!")
    placeholder:SetTextColor(0.7, 0.7, 0.7)
    
    -- Add footer
    ns.Options.CreateFooter(panel)
    
    return panel
end

-- Assign to namespace
ns.Options = Options
