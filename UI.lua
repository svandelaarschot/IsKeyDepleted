-- IsKeyDepleted UI Components
-- Interactive timeline and user interface elements

-- Get addon namespace
local addonName, ns = ...

-- Use shared namespace
ns = _G[addonName] or ns

-- Create UI namespace
ns.UI = ns.UI or {}

-- Local reference for easier access
local UI = ns.UI

-- Import other modules from namespace
local Constants = ns.Constants
local Core = ns.Core

-- UI State
UI.isInitialized = false
UI.mainFrame = nil
UI.timelineFrame = nil
UI.abandonButton = nil
UI.updateTimer = nil
UI.blizzardTrackerHidden = false
UI.isForced = false  -- Track if UI is in forced mode

-- Initialize the UI system
function UI:Initialize()
    if self.isInitialized then
        return
    end
    
    self:CreateMainFrame()
    self:CreateTimelineFrame()
    self:CreateAbandonButton()
    self:SetupUpdateTimer()
    self:HideBlizzardTracker()
    
    -- Hide UI by default - only show during M+
    self:Hide()
    
    -- State tracking
    self.lastChallengeModeState = false
    self.lastVisibilityState = false
    
    self.isInitialized = true
    if Core and Core.DebugInfo then
        Core.DebugInfo("UI system initialized (hidden by default)")
    end
end

-- Create the main frame
function UI:CreateMainFrame()
    self.mainFrame = CreateFrame("Frame", "IsKeyDepletedMainFrame", UIParent)
    self.mainFrame:SetSize(420, 160) -- Even wider frame for maximum visibility
    self.mainFrame:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
    
    -- Create black background with 0.8 opacity
    local bg = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8) -- Pure black background with 0.8 opacity
    bg:SetDrawLayer("BACKGROUND", 0)
    
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", function() 
        self.mainFrame:StartMoving()
    end)
    self.mainFrame:SetScript("OnDragStop", function() 
        self.mainFrame:StopMovingOrSizing()
        -- Save the position
        self:SavePosition()
    end)
    
    -- Make it persistent (always visible)
    self.mainFrame:SetFrameStrata("MEDIUM")
    self.mainFrame:SetFrameLevel(100)
    
    -- Add continuous update for timer (throttled to avoid performance issues)
    local updateThrottle = 0
    self.mainFrame:SetScript("OnUpdate", function(self, elapsed)
        updateThrottle = updateThrottle + elapsed
        if updateThrottle >= 0.1 then -- Update every 0.1 seconds
            updateThrottle = 0
            if UI and UI.isInitialized and Core and Core.timelineData and Core.timelineData.isActive then
                UI:UpdateDisplay()
            end
        end
    end)
    
    -- Beautiful title with glow effect
    local title = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", self.mainFrame, "TOP", 0, -10)
    title:SetText("|TInterface\\Icons\\keystone_mythic:16:16|t |cff00FFFFM+ Tracker|r")
    title:SetTextColor(0, 1, 1, 1) -- Cyan
    title:SetShadowColor(0, 0, 0, 1)
    title:SetShadowOffset(2, -2)
    
    -- Elegant status text with color coding
    self.statusText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.statusText:SetPoint("TOP", title, "BOTTOM", 0, -8)
    self.statusText:SetPoint("LEFT", self.mainFrame, "LEFT", 15, 0)
    self.statusText:SetText("|TInterface\\Icons\\spell_shadow_auraofdarkness:16:16|t |cffFFD700Status:|r |cffFF6B6BNot tracking|r")
    self.statusText:SetJustifyH("LEFT")
    self.statusText:SetShadowColor(0, 0, 0, 0.8)
    self.statusText:SetShadowOffset(2, -2)
    
    -- Stylized death count
    self.deathText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.deathText:SetPoint("TOP", self.statusText, "BOTTOM", 0, -6)
    self.deathText:SetPoint("LEFT", self.mainFrame, "LEFT", 15, 0)
    self.deathText:SetText("|TInterface\\Icons\\spell_shadow_raisedead:16:16|t |cffFF6B6BDeaths:|r |cffFFFFFF0|r")
    self.deathText:SetJustifyH("LEFT")
    self.deathText:SetShadowColor(0, 0, 0, 0.8)
    self.deathText:SetShadowOffset(2, -2)
    
    -- Prominent timer with special styling
    self.timerText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.timerText:SetPoint("TOP", self.deathText, "BOTTOM", 0, -6)
    self.timerText:SetPoint("LEFT", self.mainFrame, "LEFT", 15, 0)
    self.timerText:SetText("|TInterface\\Icons\\inv_misc_pocketwatch_01:16:16|t |cff00FF00Time:|r |cffFFFFFF0:00|r")
    self.timerText:SetJustifyH("LEFT")
    self.timerText:SetShadowColor(0, 0, 0, 1)
    self.timerText:SetShadowOffset(2, -2)
    
    -- Boss list with elegant formatting
    self.bossListText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.bossListText:SetPoint("TOP", self.timerText, "BOTTOM", 0, -5)
    self.bossListText:SetPoint("LEFT", self.mainFrame, "LEFT", 15, 0)
    self.bossListText:SetPoint("RIGHT", self.mainFrame, "RIGHT", -15, 0)
    self.bossListText:SetText("|TInterface\\Icons\\inv_misc_skull_01:16:16|t |cffFFD700Bosses:|r |cffAAAAAANone|r")
    self.bossListText:SetJustifyH("LEFT")
    self.bossListText:SetJustifyV("TOP")
    self.bossListText:SetNonSpaceWrap(true) -- Allow wrapping
    self.bossListText:SetShadowColor(0, 0, 0, 0.6)
    self.bossListText:SetShadowOffset(1, -1)
    self.bossListText:Show() -- Make sure it's visible
    
    -- Initially hidden but make it more persistent
    self.mainFrame:Hide()
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
end

-- Create the interactive timeline frame
function UI:CreateTimelineFrame()
    self.timelineFrame = CreateFrame("Frame", "IsKeyDepletedTimelineFrame", self.mainFrame)
    self.timelineFrame:SetHeight(12)
    self.timelineFrame:SetPoint("LEFT", self.mainFrame, "LEFT", 30, 0)
    self.timelineFrame:SetPoint("RIGHT", self.mainFrame, "RIGHT", -30, 0)
    self.timelineFrame:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, 45)
    
    -- Create stunning timeline background with gradient
    local timelineBg = self.timelineFrame:CreateTexture(nil, "BACKGROUND")
    timelineBg:SetAllPoints()
    timelineBg:SetColorTexture(0.1, 0.1, 0.1, 0.2) -- Transparent background
    
    -- Add subtle border
    local timelineBorder = self.timelineFrame:CreateTexture(nil, "BORDER")
    timelineBorder:SetAllPoints()
    timelineBorder:SetColorTexture(0.3, 0.3, 0.3, 0.1) -- Subtle border
    
    -- Create beautiful progress bar with gradient
    self.progressBar = CreateFrame("StatusBar", nil, self.timelineFrame)
    self.progressBar:SetHeight(10)
    self.progressBar:SetPoint("LEFT", self.timelineFrame, "LEFT", 0, 0)
    self.progressBar:SetPoint("RIGHT", self.timelineFrame, "RIGHT", 0, 0)
    self.progressBar:SetPoint("CENTER", self.timelineFrame, "CENTER", 0, 0)
    self.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.progressBar:SetStatusBarColor(0.3, 0.7, 0.3, 0.8) -- Subtle green
    self.progressBar:SetMinMaxValues(0, 1)
    self.progressBar:SetValue(0)
    
    -- Add progress bar glow effect
    local progressGlow = self.progressBar:CreateTexture(nil, "OVERLAY")
    progressGlow:SetAllPoints()
    progressGlow:SetColorTexture(0.3, 0.7, 0.3, 0.2) -- Subtle glow
    progressGlow:SetBlendMode("ADD")
    
    -- Create stunning position indicator with animation
    self.currentPosition = self.timelineFrame:CreateTexture(nil, "OVERLAY")
    self.currentPosition:SetSize(6, 25) -- Larger indicator
    self.currentPosition:SetColorTexture(1, 0.8, 0, 0.8) -- Subtle yellow
    self.currentPosition:SetPoint("LEFT", self.progressBar, "LEFT", 0, 0)
    
    -- Add position indicator glow
    local positionGlow = self.timelineFrame:CreateTexture(nil, "ARTWORK")
    positionGlow:SetSize(10, 29)
    positionGlow:SetColorTexture(1, 0.8, 0, 0.2) -- Subtle yellow glow
    positionGlow:SetBlendMode("ADD")
    positionGlow:SetPoint("CENTER", self.currentPosition, "CENTER", 0, 0)
    
    -- Add time markers for professional look
    for i = 0, 6 do
        local marker = self.timelineFrame:CreateTexture(nil, "OVERLAY")
        marker:SetSize(1, 25)
        marker:SetColorTexture(1, 1, 1, 0.3) -- White markers
        marker:SetPoint("LEFT", self.progressBar, "LEFT", (i / 6) * 220, 0)
    end
    
    -- Death markers container
    self.deathMarkers = {}
    
    -- Boss markers container
    self.bossMarkers = {}
    
    -- Time labels
    self:CreateTimeLabels()
    
    -- Make timeline interactive
    self.timelineFrame:EnableMouse(true)
    self.timelineFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            UI:OnTimelineClick()
        end
    end)
    
    -- Tooltip for timeline
    self.timelineFrame:SetScript("OnEnter", function()
        UI:ShowTimelineTooltip()
    end)
    self.timelineFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Create time labels for the timeline
function UI:CreateTimeLabels()
    local timeLabels = {}
    local totalTime = 1800 -- 30 minutes
    local labelCount = 6
    
    for i = 0, labelCount do
        local time = (totalTime / labelCount) * i
        local label = self.timelineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOM", self.timelineFrame, "BOTTOM", 
                      (i / labelCount) * (Constants.TIMELINE.WIDTH - 20) - (Constants.TIMELINE.WIDTH - 20) / 2, -2)
        label:SetText(UI:FormatTime(time))
        label:SetTextColor(1, 1, 1, 0.8)
        table.insert(timeLabels, label)
    end
end

-- Create the abandon button
function UI:CreateAbandonButton()
    self.abandonButton = CreateFrame("Button", "IsKeyDepletedAbandonButton", self.mainFrame)
    self.abandonButton:SetSize(140, 35) -- Larger for better visibility
    self.abandonButton:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, -45)
    
    -- Create stunning button background with gradient
    local buttonBg = self.abandonButton:CreateTexture(nil, "BACKGROUND")
    buttonBg:SetAllPoints()
    buttonBg:SetColorTexture(0.6, 0.2, 0.2, 0.7) -- Subtle red
    
    -- Add button border with glow
    local buttonBorder = self.abandonButton:CreateTexture(nil, "BORDER")
    buttonBorder:SetAllPoints()
    buttonBorder:SetColorTexture(0.8, 0.3, 0.3, 0.3) -- Subtle red border
    buttonBorder:SetBlendMode("ADD")
    
    -- Add button shadow
    local buttonShadow = self.abandonButton:CreateTexture(nil, "BACKGROUND")
    buttonShadow:SetPoint("TOPLEFT", 2, -2)
    buttonShadow:SetPoint("BOTTOMRIGHT", -2, 2)
    buttonShadow:SetColorTexture(0, 0, 0, 0.5)
    buttonShadow:SetDrawLayer("BACKGROUND", -1)
    
    -- Beautiful button text with glow
    self.abandonButtonText = self.abandonButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.abandonButtonText:SetPoint("CENTER", self.abandonButton, "CENTER", 0, 0)
    self.abandonButtonText:SetText("|TInterface\\Icons\\spell_shadow_psychichorrors:16:16|t |cffFFFFFFAbandon Key|r")
    self.abandonButtonText:SetShadowColor(0, 0, 0, 1)
    self.abandonButtonText:SetShadowOffset(2, -2)
    
    -- Button functionality
    self.abandonButton:SetScript("OnClick", function()
        UI:OnAbandonClick()
    end)
    
    -- Add hover effects
    self.abandonButton:SetScript("OnEnter", function()
        buttonBorder:SetColorTexture(0.9, 0.4, 0.4, 0.5) -- Subtle glow on hover
        self.abandonButtonText:SetText("|TInterface\\Icons\\spell_shadow_psychichorrors:16:16|t |cffFFAAAAAbandon Key|r")
    end)
    self.abandonButton:SetScript("OnLeave", function()
        buttonBorder:SetColorTexture(0.8, 0.3, 0.3, 0.3) -- Normal border
        self.abandonButtonText:SetText("|TInterface\\Icons\\spell_shadow_psychichorrors:16:16|t |cffFFFFFFAbandon Key|r")
    end)
    
    -- Initially hidden
    self.abandonButton:Hide()
end

-- Setup update timer
function UI:SetupUpdateTimer()
    self.updateTimer = CreateFrame("Frame")
    self.lastUpdate = 0
    self.updateTimer:SetScript("OnUpdate", function(frame, elapsed)
        UI.lastUpdate = UI.lastUpdate + elapsed
        -- Only update every 0.5 seconds to prevent flickering
        if UI.lastUpdate >= 0.5 then
            UI:Update()
            UI:MonitorBlizzardTracker()
            UI.lastUpdate = 0
        end
    end)
end

-- Update the display elements (called continuously)
function UI:UpdateDisplay()
    if not self.isInitialized or not Core then
        return
    end
    
    -- Only update if we're tracking
    if not Core.timelineData or not Core.timelineData.isActive then
        return
    end
    
    -- Get current stats
    local stats = Core:GetTimelineStats()
    
    -- Update status with beautiful styling
    local statusColor = "|cffAAAAAA" -- Gray
    if stats.timeabilityStatus == Constants.TIMEABILITY.TIMEABLE then
        statusColor = "|cff00FF00" -- Green
    elseif stats.timeabilityStatus == Constants.TIMEABILITY.BORDERLINE then
        statusColor = "|cffFFD700" -- Yellow
    elseif stats.timeabilityStatus == Constants.TIMEABILITY.NOT_TIMEABLE then
        statusColor = "|cffFF6B6B" -- Red
    end
    
    local statusText = stats.timeabilityStatus or "UNKNOWN"
    self.statusText:SetText("|TInterface\\Icons\\spell_shadow_auraofdarkness:16:16|t |cffFFD700Status:|r " .. statusColor .. statusText .. "|r")
    
    -- Update death count with beautiful styling
    local deathColor = stats.deathCount > 0 and "|cffFF6B6B" or "|cffFFFFFF"
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    
    -- Show penalty only for M+ dungeons
    local deathText = "|TInterface\\Icons\\spell_shadow_raisedead:16:16|t |cffFF6B6BDeaths:|r " .. deathColor .. stats.deathCount .. "|r"
    if inChallengeMode and stats.deathPenalty > 0 then
        deathText = deathText .. " |cffAAAAAA(+" .. stats.deathPenalty .. "s penalty)|r"
    end
    self.deathText:SetText(deathText)
    
    -- Update timer with stunning styling - show elapsed time and remaining if applicable
    local elapsedTime = stats.totalTime - stats.remainingTime
    local timeColor = elapsedTime > 0 and "|cff00FF00" or "|cffFFFFFF"
    local remainingColor = stats.remainingTime > 0 and "|cffFFD700" or "|cffFF6B6B"
    
    -- Check if we're in a timed dungeon (M+ only)
    local hasTimer = inChallengeMode and stats.totalTime > 0
    
    -- Show elapsed time, and remaining time only if in timed dungeon
    local timeText = "|TInterface\\Icons\\inv_misc_pocketwatch_01:16:16|t |cff00FF00Time:|r " .. timeColor .. UI:FormatTime(elapsedTime) .. "|r"
    if hasTimer and stats.remainingTime > 0 then
        timeText = timeText .. " |cffAAAAAA(|r" .. remainingColor .. UI:FormatTime(stats.remainingTime) .. "|cffAAAAAA left)|r"
    end
    self.timerText:SetText(timeText)
    
    -- Update boss list with beautiful styling
    local bossList = Core:GetFormattedBossList()
    if #bossList > 0 then
        local bossText = "|TInterface\\Icons\\inv_misc_skull_01:16:16|t |cffFFD700Bosses:|r\n"
        for i, boss in ipairs(bossList) do
            bossText = bossText .. "|cffFFFFFF" .. boss.name .. "|r |cffAAAAAA(" .. boss.time .. ")|r"
            if i < #bossList then
                bossText = bossText .. "\n"
            end
        end
        self.bossListText:SetText(bossText)
        self.bossListText:Show() -- Ensure it's visible
        
        -- Adjust frame height based on boss count
        local baseHeight = 180 -- Increased for better spacing
        local bossHeight = #bossList * 22 -- 22 pixels per boss for better readability
        local newHeight = baseHeight + bossHeight
        self.mainFrame:SetHeight(newHeight)
        
        -- Reposition timeline frame to stay at bottom with proper spacing
        self.timelineFrame:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, 45)
        
        -- Adjust boss list text positioning to avoid overlap
        self.bossListText:SetPoint("TOP", self.timerText, "BOTTOM", 0, -5)
        self.bossListText:SetPoint("LEFT", self.mainFrame, "LEFT", 10, 0)
        self.bossListText:SetPoint("RIGHT", self.mainFrame, "RIGHT", -10, 0)
        self.bossListText:SetPoint("BOTTOM", self.timelineFrame, "TOP", 0, -10)
    else
        self.bossListText:SetText("|TInterface\\Icons\\inv_misc_skull_01:16:16|t |cffFFD700Bosses:|r |cffAAAAAANone|r")
        
        -- Reset to base height
        self.mainFrame:SetHeight(180)
        self.timelineFrame:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, 5)
    end
    
    -- Update progress bar
    self.progressBar:SetValue(stats.progressPercentage)
    
    -- Update current position indicator
    local progressBarWidth = self.progressBar:GetWidth()
    local position = stats.progressPercentage * (progressBarWidth - 20)
    self.currentPosition:SetPoint("LEFT", self.progressBar, "LEFT", position, 0)
    
    -- Update abandon button visibility
    if stats.shouldShowAbandon then
        self.abandonButton:Show()
    else
        self.abandonButton:Hide()
    end
    
    -- Update death markers
    self:UpdateDeathMarkers()
    
    -- Update boss markers
    self:UpdateBossMarkers()
end

-- Update the UI
function UI:Update()
    if not self.isInitialized then
        return
    end
    
    -- Check if Core module is available
    if not Core then
        return
    end
    
    -- Check if we're in challenge mode or follower dungeon
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    local inFollowerDungeon = C_Scenario.IsInScenario() and C_Scenario.GetInfo()
    
    -- Debug visibility state
    if Core and Core.DebugVerbose then
        Core.DebugVerbose("UI Update - Challenge Mode: %s, Follower Dungeon: %s, UI Visible: %s, Tracking: %s", 
            tostring(inChallengeMode), 
            tostring(inFollowerDungeon), 
            tostring(self.mainFrame and self.mainFrame:IsVisible()), 
            tostring(Core.timelineData and Core.timelineData.isActive))
    end
    
    -- If in challenge mode or follower dungeon and not tracking, try to restore or start tracking
    if (inChallengeMode or inFollowerDungeon) and Core.timelineData and not Core.timelineData.isActive then
        -- First try to restore previous run
        local restored = Core:RestoreCurrentRun()
        if restored then
            self:Show() -- Show UI when restoring
            if Core and Core.DebugInfo then
                Core.DebugInfo("Restored previous run - %d deaths, %d bosses", Core.deathCount, #Core.timelineData.bosses)
            end
        else
            -- Start new tracking
            if inChallengeMode then
                local keyLevel = C_ChallengeMode.GetActiveKeystoneLevel()
                local dungeonId = C_ChallengeMode.GetActiveKeystoneMapID()
                
                if keyLevel and dungeonId then
                    Core:StartKeyTracking(keyLevel, dungeonId)
                    self:Show() -- Show UI when starting tracking
                    if Core and Core.DebugInfo then
                        Core.DebugInfo("Auto-started challenge mode tracking - Key Level %d", keyLevel)
                    end
                end
            elseif inFollowerDungeon then
                -- Start with test data for follower dungeons
                Core:StartKeyTracking(15, 1) -- Test key level 15, dungeon ID 1
                self:Show() -- Show UI when starting tracking
                if Core and Core.DebugInfo then
                    Core.DebugInfo("Auto-started follower dungeon tracking - Test Key Level 15")
                end
            end
        end
    end
    
    -- Only hide if explicitly not in challenge mode AND not in follower dungeon AND we're currently visible
    -- But don't hide if we're in forced mode
    if not inChallengeMode and not inFollowerDungeon then
        if self.mainFrame and self.mainFrame:IsVisible() then
            -- Check if we're in forced mode
            if not self.isForced then
                if Core and Core.DebugInfo then
                    Core.DebugInfo("Hiding UI - not in challenge mode or follower dungeon")
                end
                self:Hide()
            else
                if Core and Core.DebugInfo then
                    Core.DebugInfo("UI in forced mode - not hiding despite not being in challenge mode or follower dungeon")
                end
            end
        end
        return
    end
    
    -- Update current time in Core
    Core:UpdateCurrentTime()
    
    local stats = Core:GetTimelineStats()
    
    -- Safety check for stats
    if not stats then
        return
    end
    
    -- Debug: Check if we're tracking
    if Core.timelineData and Core.timelineData.isActive and Core.currentTime and Core.currentTime > 0 then
        if Core and Core.DebugVerbose then
            Core.DebugVerbose("UI Update - Time: %s, Status: %s", Core:FormatTime(Core.currentTime), stats.timeabilityStatus)
        end
    end
    
    -- Update status text with beautiful styling
    local statusColor
    if stats.timeabilityStatus == Constants.TIMEABILITY.TIMEABLE then
        statusColor = "|cff00FF00" -- Green
    elseif stats.timeabilityStatus == Constants.TIMEABILITY.BORDERLINE then
        statusColor = "|cffFFD700" -- Yellow
    elseif stats.timeabilityStatus == Constants.TIMEABILITY.NOT_TIMEABLE then
        statusColor = "|cffFF6B6B" -- Red
    else
        statusColor = "|cffAAAAAA" -- Gray
    end
    
    local statusText = stats.timeabilityStatus or "UNKNOWN"
    self.statusText:SetText("|TInterface\\Icons\\spell_shadow_auraofdarkness:16:16|t |cffFFD700Status:|r " .. statusColor .. statusText .. "|r")
    
    -- Update death count with beautiful styling
    local deathColor = stats.deathCount > 0 and "|cffFF6B6B" or "|cffFFFFFF"
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    
    -- Show penalty only for M+ dungeons
    local deathText = "|TInterface\\Icons\\spell_shadow_raisedead:16:16|t |cffFF6B6BDeaths:|r " .. deathColor .. stats.deathCount .. "|r"
    if inChallengeMode and stats.deathPenalty > 0 then
        deathText = deathText .. " |cffAAAAAA(+" .. stats.deathPenalty .. "s penalty)|r"
    end
    self.deathText:SetText(deathText)
    
    -- Update timer with stunning styling - show elapsed time and remaining if applicable
    local elapsedTime = stats.totalTime - stats.remainingTime
    local timeColor = elapsedTime > 0 and "|cff00FF00" or "|cffFFFFFF"
    local remainingColor = stats.remainingTime > 0 and "|cffFFD700" or "|cffFF6B6B"
    
    -- Check if we're in a timed dungeon (M+ only)
    local inChallengeMode = C_ChallengeMode.IsChallengeModeActive()
    local hasTimer = inChallengeMode and stats.totalTime > 0
    
    -- Show elapsed time, and remaining time only if in timed dungeon
    local timeText = "|TInterface\\Icons\\inv_misc_pocketwatch_01:16:16|t |cff00FF00Time:|r " .. timeColor .. UI:FormatTime(elapsedTime) .. "|r"
    if hasTimer and stats.remainingTime > 0 then
        timeText = timeText .. " |cffAAAAAA(|r" .. remainingColor .. UI:FormatTime(stats.remainingTime) .. "|cffAAAAAA left)|r"
    end
    self.timerText:SetText(timeText)
    
    -- Update boss list with beautiful styling
    local bossList = Core:GetFormattedBossList()
    if #bossList > 0 then
        local bossText = "|TInterface\\Icons\\inv_misc_skull_01:16:16|t |cffFFD700Bosses:|r\n"
        for i, boss in ipairs(bossList) do
            bossText = bossText .. "|cffFFFFFF" .. boss.name .. "|r |cffAAAAAA(" .. boss.time .. ")|r"
            if i < #bossList then
                bossText = bossText .. "\n"
            end
        end
        self.bossListText:SetText(bossText)
        self.bossListText:Show() -- Ensure it's visible
        
        -- Adjust frame height based on boss count
        local baseHeight = 180 -- Increased for better spacing
        local bossHeight = #bossList * 22 -- 22 pixels per boss for better readability
        local newHeight = baseHeight + bossHeight
        self.mainFrame:SetHeight(newHeight)
        
        -- Reposition timeline frame to stay at bottom with proper spacing
        self.timelineFrame:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, 45)
        
        -- Adjust boss list text positioning to avoid overlap
        self.bossListText:SetPoint("TOP", self.timerText, "BOTTOM", 0, -5)
        self.bossListText:SetPoint("LEFT", self.mainFrame, "LEFT", 10, 0)
        self.bossListText:SetPoint("RIGHT", self.mainFrame, "RIGHT", -10, 0)
        self.bossListText:SetPoint("BOTTOM", self.timelineFrame, "TOP", 0, -10)
    else
        self.bossListText:SetText("|TInterface\\Icons\\inv_misc_skull_01:16:16|t |cffFFD700Bosses:|r |cffAAAAAANone|r")
        
        -- Reset to base height
        self.mainFrame:SetHeight(180)
        self.timelineFrame:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, 5)
    end
    
    -- Update progress bar
    self.progressBar:SetValue(stats.progressPercentage)
    
    -- Update current position indicator
    local progressBarWidth = self.progressBar:GetWidth()
    local position = stats.progressPercentage * (progressBarWidth - 20)
    self.currentPosition:SetPoint("LEFT", self.progressBar, "LEFT", position, 0)
    
    -- Update abandon button visibility
    if stats.shouldShowAbandon then
        self.abandonButton:Show()
    else
        self.abandonButton:Hide()
    end
    
    -- Update death markers
    self:UpdateDeathMarkers()
    
    -- Update boss markers
    self:UpdateBossMarkers()
end

-- Update death markers on timeline
function UI:UpdateDeathMarkers()
    local timelineData = Core:GetTimelineData()
    local totalTime = timelineData.totalTime
    
    -- Clear existing markers
    for _, marker in ipairs(self.deathMarkers) do
        marker:Hide()
    end
    self.deathMarkers = {}
    
    -- Create new markers
    for i, death in ipairs(timelineData.deaths) do
        local marker = self.timelineFrame:CreateTexture(nil, "OVERLAY")
        marker:SetSize(Constants.TIMELINE.MARKER_SIZE, Constants.TIMELINE.MARKER_SIZE)
        marker:SetColorTexture(Constants.TIMELINE.DEATH_MARKER_COLOR.r,
                              Constants.TIMELINE.DEATH_MARKER_COLOR.g,
                              Constants.TIMELINE.DEATH_MARKER_COLOR.b,
                              Constants.TIMELINE.DEATH_MARKER_COLOR.a)
        
        local position = (death.time / totalTime) * (Constants.TIMELINE.WIDTH - 20)
        marker:SetPoint("CENTER", self.progressBar, "LEFT", position, 0)
        
        -- Tooltip for death marker
        marker:SetScript("OnEnter", function()
            GameTooltip:SetOwner(marker, "ANCHOR_TOP")
            GameTooltip:SetText("Death #" .. death.deathNumber)
            GameTooltip:AddLine("Time: " .. UI:FormatTime(death.time), 1, 1, 1)
            GameTooltip:AddLine("Reason: " .. death.reason, 1, 1, 1)
            GameTooltip:Show()
        end)
        marker:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        table.insert(self.deathMarkers, marker)
    end
end

-- Update boss markers on timeline
function UI:UpdateBossMarkers()
    local timelineData = Core:GetTimelineData()
    local totalTime = timelineData.totalTime
    
    -- Clear existing markers
    for _, marker in ipairs(self.bossMarkers) do
        marker:Hide()
    end
    self.bossMarkers = {}
    
    -- Create new markers
    for i, boss in ipairs(timelineData.bosses) do
        local marker = self.timelineFrame:CreateTexture(nil, "OVERLAY")
        marker:SetSize(Constants.TIMELINE.MARKER_SIZE, Constants.TIMELINE.MARKER_SIZE)
        marker:SetColorTexture(Constants.TIMELINE.BOSS_MARKER_COLOR.r,
                              Constants.TIMELINE.BOSS_MARKER_COLOR.g,
                              Constants.TIMELINE.BOSS_MARKER_COLOR.b,
                              Constants.TIMELINE.BOSS_MARKER_COLOR.a)
        
        local position = (boss.time / totalTime) * (Constants.TIMELINE.WIDTH - 20)
        marker:SetPoint("CENTER", self.progressBar, "LEFT", position, 0)
        
        -- Tooltip for boss marker
        marker:SetScript("OnEnter", function()
            GameTooltip:SetOwner(marker, "ANCHOR_TOP")
            GameTooltip:SetText("Boss: " .. boss.name)
            GameTooltip:AddLine("Time: " .. UI:FormatTime(boss.time), 1, 1, 1)
            GameTooltip:AddLine("Status: Completed", 0, 1, 0)
            GameTooltip:Show()
        end)
        marker:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        table.insert(self.bossMarkers, marker)
    end
end

-- Handle timeline click
function UI:OnTimelineClick()
    local timelineData = Core:GetTimelineData()
    if not timelineData.isActive then
        return
    end
    
    -- Show timeline details
    if Core and Core.DebugInfo then
        Core.DebugInfo("Timeline clicked - showing details")
    end
    -- TODO: Implement timeline details popup
end

-- Handle abandon button click
function UI:OnAbandonClick()
    Core:ExecuteAbandon()
end

-- Show timeline tooltip
function UI:ShowTimelineTooltip()
    local timelineData = Core:GetTimelineData()
    if not timelineData.isActive then
        return
    end
    
    GameTooltip:SetOwner(self.timelineFrame, "ANCHOR_TOP")
    GameTooltip:SetText("Timeline Progress")
    GameTooltip:AddLine("Deaths: " .. #timelineData.deaths, 1, 1, 1)
    GameTooltip:AddLine("Bosses: " .. #timelineData.bosses, 1, 1, 1)
    GameTooltip:AddLine("Events: " .. #timelineData.events, 1, 1, 1)
    GameTooltip:Show()
end

-- Format time for display
function UI:FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, secs)
end

-- Show the main frame
function UI:Show()
    if self.mainFrame then
        -- Load saved position if available
        self:LoadPosition()
        self.mainFrame:Show()
        -- Make it persistent and always on top
        self.mainFrame:SetFrameStrata("MEDIUM")
        self.mainFrame:SetFrameLevel(100)
    end
end

-- Hide the main frame
function UI:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

-- Toggle the main frame
function UI:Toggle()
    if self.mainFrame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

-- Hide Blizzard's default dungeon tracker
function UI:HideBlizzardTracker()
    local hiddenCount = 0
    
    -- Hide all Blizzard challenge mode frames
    for _, frameName in ipairs(Constants.BLIZZARD_TRACKER.FRAMES_TO_HIDE) do
        local frame = _G[frameName]
        if frame and frame:IsVisible() then
            frame:Hide()
            hiddenCount = hiddenCount + 1
        end
    end
    
    self.blizzardTrackerHidden = true
    
    if hiddenCount > 0 then
        if Core and Core.DebugInfo then
            Core.DebugInfo("Blizzard dungeon tracker hidden (%d frames)", hiddenCount)
        end
    end
end

-- Show Blizzard's default dungeon tracker
function UI:ShowBlizzardTracker()
    local shownCount = 0
    
    -- Show all Blizzard challenge mode frames
    for _, frameName in ipairs(Constants.BLIZZARD_TRACKER.FRAMES_TO_HIDE) do
        local frame = _G[frameName]
        if frame then
            frame:Show()
            shownCount = shownCount + 1
        end
    end
    
    self.blizzardTrackerHidden = false
    
    if shownCount > 0 then
        if Core and Core.DebugInfo then
            Core.DebugInfo("Blizzard dungeon tracker shown (%d frames)", shownCount)
        end
    end
end

-- Toggle Blizzard tracker visibility
function UI:ToggleBlizzardTracker()
    if self.blizzardTrackerHidden then
        self:ShowBlizzardTracker()
    else
        self:HideBlizzardTracker()
    end
end

-- Check if Blizzard tracker is hidden
function UI:IsBlizzardTrackerHidden()
    return self.blizzardTrackerHidden
end

-- Monitor and maintain Blizzard tracker hidden state
function UI:MonitorBlizzardTracker()
    if not self.blizzardTrackerHidden then
        return
    end
    
    -- Re-hide Blizzard tracker frames if they become visible
    for _, frameName in ipairs(Constants.BLIZZARD_TRACKER.FRAMES_TO_HIDE) do
        local frame = _G[frameName]
        if frame and frame:IsVisible() then
            frame:Hide()
        end
    end
end

-- Save UI position
function UI:SavePosition()
    if self.mainFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = self.mainFrame:GetPoint()
        if not IsKeyDepletedDB.ui then
            IsKeyDepletedDB.ui = {}
        end
        IsKeyDepletedDB.ui.position = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
        if Core and Core.DebugInfo then
            Core.DebugInfo("UI position saved: %s, %s, %s, %d, %d", point, relativeTo, relativePoint, xOfs, yOfs)
        end
    end
end

-- Load UI position
function UI:LoadPosition()
    if self.mainFrame and IsKeyDepletedDB.ui and IsKeyDepletedDB.ui.position then
        local pos = IsKeyDepletedDB.ui.position
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
        if Core and Core.DebugInfo then
            Core.DebugInfo("UI position loaded: %s, %s, %s, %d, %d", pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
        end
    end
end

-- Assign to namespace
ns.UI = UI
