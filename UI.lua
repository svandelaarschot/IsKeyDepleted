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

-- Import Constants from namespace
local Constants = ns.Constants

-- UI State
UI.isInitialized = false
UI.mainFrame = nil
UI.timelineFrame = nil
UI.abandonButton = nil
UI.updateTimer = nil
UI.blizzardTrackerHidden = false

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
    
    self.isInitialized = true
    Core.DebugInfo("UI system initialized")
end

-- Create the main frame
function UI:CreateMainFrame()
    self.mainFrame = CreateFrame("Frame", "IsKeyDepletedMainFrame", UIParent)
    self.mainFrame:SetSize(450, 120)
    self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    self.mainFrame:SetBackdropColor(0, 0, 0, 0.8)
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", function() self.mainFrame:StartMoving() end)
    self.mainFrame:SetScript("OnDragStop", function() self.mainFrame:StopMovingOrSizing() end)
    
    -- Title
    local title = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", self.mainFrame, "TOP", 0, -10)
    title:SetText("|cff39FF14IsKeyDepleted|r")
    
    -- Status text
    self.statusText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.statusText:SetPoint("TOP", title, "BOTTOM", 0, -5)
    self.statusText:SetText("Status: Not tracking")
    
    -- Death count text
    self.deathText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.deathText:SetPoint("TOP", self.statusText, "BOTTOM", 0, -5)
    self.deathText:SetText("Deaths: 0")
    
    -- Timer text
    self.timerText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.timerText:SetPoint("TOP", self.deathText, "BOTTOM", 0, -5)
    self.timerText:SetText("Time: 0:00")
    
    -- Initially hidden
    self.mainFrame:Hide()
end

-- Create the interactive timeline frame
function UI:CreateTimelineFrame()
    self.timelineFrame = CreateFrame("Frame", "IsKeyDepletedTimelineFrame", self.mainFrame)
    self.timelineFrame:SetSize(Constants.TIMELINE.WIDTH, Constants.TIMELINE.HEIGHT)
    self.timelineFrame:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, 10)
    
    -- Timeline background
    local timelineBg = self.timelineFrame:CreateTexture(nil, "BACKGROUND")
    timelineBg:SetAllPoints()
    timelineBg:SetColorTexture(Constants.TIMELINE.BACKGROUND_COLOR.r, 
                              Constants.TIMELINE.BACKGROUND_COLOR.g, 
                              Constants.TIMELINE.BACKGROUND_COLOR.b, 
                              Constants.TIMELINE.BACKGROUND_COLOR.a)
    
    -- Progress bar
    self.progressBar = CreateFrame("StatusBar", nil, self.timelineFrame)
    self.progressBar:SetSize(Constants.TIMELINE.WIDTH - 20, Constants.TIMELINE.PROGRESS_BAR_HEIGHT)
    self.progressBar:SetPoint("CENTER", self.timelineFrame, "CENTER", 0, 0)
    self.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.progressBar:SetStatusBarColor(Constants.TIMELINE.PROGRESS_BAR_COLOR.r,
                                      Constants.TIMELINE.PROGRESS_BAR_COLOR.g,
                                      Constants.TIMELINE.PROGRESS_BAR_COLOR.b,
                                      Constants.TIMELINE.PROGRESS_BAR_COLOR.a)
    self.progressBar:SetMinMaxValues(0, 1)
    self.progressBar:SetValue(0)
    
    -- Current position indicator
    self.currentPosition = self.timelineFrame:CreateTexture(nil, "OVERLAY")
    self.currentPosition:SetSize(4, Constants.TIMELINE.PROGRESS_BAR_HEIGHT + 4)
    self.currentPosition:SetColorTexture(Constants.TIMELINE.CURRENT_POSITION_COLOR.r,
                                        Constants.TIMELINE.CURRENT_POSITION_COLOR.g,
                                        Constants.TIMELINE.CURRENT_POSITION_COLOR.b,
                                        Constants.TIMELINE.CURRENT_POSITION_COLOR.a)
    self.currentPosition:SetPoint("LEFT", self.progressBar, "LEFT", 0, 0)
    
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
    self.abandonButton:SetSize(120, 30)
    self.abandonButton:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 0, -40)
    
    -- Button background
    local buttonBg = self.abandonButton:CreateTexture(nil, "BACKGROUND")
    buttonBg:SetAllPoints()
    buttonBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    
    -- Button text
    self.abandonButtonText = self.abandonButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.abandonButtonText:SetPoint("CENTER", self.abandonButton, "CENTER", 0, 0)
    self.abandonButtonText:SetText("ABANDON KEY")
    self.abandonButtonText:SetTextColor(1, 1, 1, 1)
    
    -- Button functionality
    self.abandonButton:SetScript("OnClick", function()
        UI:OnAbandonClick()
    end)
    
    -- Button hover effects
    self.abandonButton:SetScript("OnEnter", function()
        buttonBg:SetColorTexture(0.9, 0.3, 0.3, 0.9)
    end)
    self.abandonButton:SetScript("OnLeave", function()
        buttonBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    end)
    
    -- Initially hidden
    self.abandonButton:Hide()
end

-- Setup update timer
function UI:SetupUpdateTimer()
    self.updateTimer = CreateFrame("Frame")
    self.updateTimer:SetScript("OnUpdate", function(self, elapsed)
        UI:Update()
        UI:MonitorBlizzardTracker()
    end)
end

-- Update the UI
function UI:Update()
    if not self.isInitialized then
        return
    end
    
    local stats = Core:GetTimelineStats()
    
    -- Update status text
    local statusColor = Constants.COLORS.NEUTRAL
    if stats.timeabilityStatus == Constants.TIMEABILITY.TIMEABLE then
        statusColor = Constants.COLORS.TIMEABLE
    elseif stats.timeabilityStatus == Constants.TIMEABILITY.BORDERLINE then
        statusColor = Constants.COLORS.BORDERLINE
    elseif stats.timeabilityStatus == Constants.TIMEABILITY.NOT_TIMEABLE then
        statusColor = Constants.COLORS.NOT_TIMEABLE
    end
    
    self.statusText:SetText("Status: |cff" .. 
                          string.format("%02x%02x%02x", 
                                      statusColor.r * 255, 
                                      statusColor.g * 255, 
                                      statusColor.b * 255) .. 
                          stats.timeabilityStatus .. "|r")
    
    -- Update death count
    self.deathText:SetText("Deaths: " .. stats.deathCount .. " (+" .. stats.deathPenalty .. "s penalty)")
    
    -- Update timer
    self.timerText:SetText("Time: " .. UI:FormatTime(stats.remainingTime))
    
    -- Update progress bar
    self.progressBar:SetValue(stats.progressPercentage)
    
    -- Update current position indicator
    local position = stats.progressPercentage * (Constants.TIMELINE.WIDTH - 20)
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
    Core.DebugInfo("Timeline clicked - showing details")
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
        self.mainFrame:Show()
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
        Core.DebugInfo("Blizzard dungeon tracker hidden (%d frames)", hiddenCount)
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
        Core.DebugInfo("Blizzard dungeon tracker shown (%d frames)", shownCount)
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

-- Assign to namespace
ns.UI = UI