local selectedTab = 1
local playerTalentPoints = 0
local talentZoom = 1.0
local talentPanX = 0.0
local talentPanY = 0.0
local canvasDragging = false
local visibleNodes = {}
local talentsById = {}
local talentIndexById = {}

local TALENT_NODE_SIZE = 128
local TALENT_MIN_ZOOM = 0.35
local TALENT_MAX_ZOOM = 1.60

-- Visual states for a talent node, used to convey at a glance whether a talent
-- can be spent into right now.
--   "maxed"     - fully ranked, nothing more to spend
--   "available" - learnable right now (points available + requirements met)
--   "nopoints"  - requirements met, but no talent points left to spend
--   "blocked"   - requirements not met yet (missing prerequisites / required points)
-- Unavailable nodes are pushed dark and cold so they recede; the only nodes that
-- read as "warm / colorful" are the ones you can actually act on. Available nodes
-- additionally get a green glow halo so they pop out at a glance.
local TALENT_ICON_TINT = {
    maxed = "FFFFFFFF",
    available = "FFFFFFFF",
    nopoints = "FF5A6470",
    blocked = "FF454C57",
}
local TALENT_NODE_OPACITY = {
    maxed = 1.0,
    available = 1.0,
    nopoints = 0.5,
    blocked = 0.4,
}
local TALENT_GLOW_TINT = {
    maxed = "00000000",
    available = "FF3BE07A",
    nopoints = "00000000",
    blocked = "00000000",
}
local TALENT_RANK_COLOR = {
    maxed = "FFFFD100",
    available = "FF42E67A",
    nopoints = "FFA0A8B2",
    blocked = "FF7A828E",
}

-- Prerequisite line colors / thickness.
local TALENT_LINE_COLOR_MET = "FF42D1D8"
local TALENT_LINE_COLOR_UNMET = "66525A66"

local function TalentFrame_GetSelectedTabInfo()
    return GetTalentTabInfo(selectedTab - 1)
end

local function TalentFrame_ApplyView()
    local tab = TalentFrame_GetSelectedTabInfo()
    if tab == nil then
        return
    end

    TalentFrameCanvasContent:SetSize(tab.canvasWidth * talentZoom, tab.canvasHeight * talentZoom)
    TalentFrameCanvasContent:ClearAnchors()
    TalentFrameCanvasContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, talentPanY)
    TalentFrameCanvasContent:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, talentPanX)
end

local function TalentFrame_ResetView()
    local tab = TalentFrame_GetSelectedTabInfo()
    if tab == nil then
        return
    end

    talentZoom = math.max(TALENT_MIN_ZOOM, math.min(TALENT_MAX_ZOOM, tab.initialZoom))
    talentPanX = (TalentFrameCanvasViewport:GetWidth() - tab.canvasWidth * talentZoom) * 0.5
    talentPanY = (TalentFrameCanvasViewport:GetHeight() - tab.canvasHeight * talentZoom) * 0.5
    TalentFrame_ApplyView()
end

local function TalentFrame_SetZoom(newZoom)
    local oldZoom = talentZoom
    newZoom = math.max(TALENT_MIN_ZOOM, math.min(TALENT_MAX_ZOOM, newZoom))
    if math.abs(newZoom - oldZoom) < 0.001 then
        return
    end

    local centerX = TalentFrameCanvasViewport:GetWidth() * 0.5
    local centerY = TalentFrameCanvasViewport:GetHeight() * 0.5
    local canvasCenterX = (centerX - talentPanX) / oldZoom
    local canvasCenterY = (centerY - talentPanY) / oldZoom
    talentZoom = newZoom
    talentPanX = centerX - canvasCenterX * talentZoom
    talentPanY = centerY - canvasCenterY * talentZoom
    TalentFrame_UpdateTalents()
end

function TalentFrame_Toggle()
    if TalentFrame:IsVisible() then
        HideUIPanel(TalentFrame)
    else
        ShowUIPanel(TalentFrame)
    end
end

function TalentFrame_UpdateTabs()
    TalentFrameTabContainer:RemoveAllChildren()
    local count = GetNumTalentTabs()
    local tabWidth = 360
    local startX = math.max(0, (TalentFrameTabContainer:GetWidth() - count * tabWidth) * 0.5)

    for index = 1, count do
        local tab = GetTalentTabInfo(index - 1)
        local button = TalentFrameTabButtonTemplate:Clone()
        button.id = index
        button:SetText(tab.name)
        button:SetChecked(index == selectedTab)
        button:SetClickedHandler(TalentFrameTab_OnClick)
        button:ClearAnchors()
        button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0)
        button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, startX + (index - 1) * tabWidth)
        TalentFrameTabContainer:AddChild(button)
    end
end

function TalentFrameTab_OnClick(self)
    if self.id ~= selectedTab then
        selectedTab = self.id
        TalentFrame_ResetView()
        TalentFrame_Update(TalentFrame)
    else
        TalentFrame_UpdateTabs()
    end
end

local function TalentFrame_CreateLine(startTalent, endTalent, prerequisite)
    local line = TalentFrameLineTemplate:Clone()
    line:SetSize(TalentFrameCanvasContent:GetWidth(), TalentFrameCanvasContent:GetHeight())
    line:ClearAnchors()
    line:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0)
    line:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0)
    line:SetProperty("StartX", tostring(startTalent.positionX * talentZoom))
    line:SetProperty("StartY", tostring(startTalent.positionY * talentZoom))
    line:SetProperty("EndX", tostring(endTalent.positionX * talentZoom))
    line:SetProperty("EndY", tostring(endTalent.positionY * talentZoom))
    line:SetProperty("Thickness", tostring((prerequisite.met and 8 or 4) * talentZoom))
    line:SetProperty("Color", prerequisite.met and TALENT_LINE_COLOR_MET or TALENT_LINE_COLOR_UNMET)
    line:SetFrameLevel(0)
    TalentFrameCanvasContent:AddChild(line)
end

-- Determines the visual state of a talent node (see TALENT_ICON_TINT above).
-- Note: talent.canLearn already bundles "points available + rank < maxRank +
-- required points spent + prerequisites met", so when it is false we recompute
-- the requirements here to tell apart "merely out of points" from "blocked".
local function TalentFrame_GetNodeState(talent, talentIndex)
    if talent.rank >= talent.maxRank then
        return "maxed"
    end
    if talent.canLearn then
        return "available"
    end

    local prerequisitesMet = true
    local prerequisiteCount = GetNumTalentPrerequisites(selectedTab - 1, talentIndex)
    for prerequisiteIndex = 0, prerequisiteCount - 1 do
        local prerequisite = GetTalentPrerequisiteInfo(selectedTab - 1, talentIndex, prerequisiteIndex)
        if prerequisite ~= nil and not prerequisite.met then
            prerequisitesMet = false
            break
        end
    end

    local spent = GetTalentPointsSpentInTab(selectedTab - 1)
    if prerequisitesMet and spent >= talent.requiredPoints then
        -- Every requirement is satisfied; the only thing missing is free points.
        return "nopoints"
    end
    return "blocked"
end

local function TalentFrame_CreateNode(talent, talentIndex)
    local button = TalentFrameTalentTemplate:Clone()
    local size = TALENT_NODE_SIZE * talent.nodeScale * talentZoom
    local state = TalentFrame_GetNodeState(talent, talentIndex)
    -- NOTE: 'id' is a real (C++ backed) frame property and persists across handler calls, whereas
    -- arbitrary Lua fields set on the frame wrapper do not. So we key the talent index by frame id.
    button.id = talent.id
    button:SetSize(size, size)
    button:ClearAnchors()
    button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, talent.positionY * talentZoom - size * 0.5)
    button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, talent.positionX * talentZoom - size * 0.5)
    button:SetProperty("Icon", talent.icon or "")
    button:SetProperty("IconTint", TALENT_ICON_TINT[state])
    button:SetProperty("GlowTint", TALENT_GLOW_TINT[state])
    button:SetChecked(state == "maxed")
    button:SetOpacity(TALENT_NODE_OPACITY[state])
    button:SetClickedHandler(TalentFrameTalent_OnClick)
    button:SetOnEnterHandler(TalentFrameTalent_OnEnter)
    button:SetOnLeaveHandler(TalentFrameTalent_OnLeave)
    button:SetFrameLevel(10)

    local rank = button:GetChild(0)
    rank:SetText(string.format("%d/%d", talent.rank, talent.maxRank))
    rank:SetProperty("TextColor", TALENT_RANK_COLOR[state])

    TalentFrameCanvasContent:AddChild(button)
    visibleNodes[talent.id] = button
end

function TalentFrame_UpdateTalents()
    local tab = TalentFrame_GetSelectedTabInfo()
    if tab == nil then
        TalentFrameCanvasContent:RemoveAllChildren()
        return
    end

    TalentFrameCanvasViewport:SetProperty("Background", tab.background ~= "" and tab.background or "Interface/GameUI/TalentFrameBackground.htex")
    TalentFrame_ApplyView()
    TalentFrameCanvasContent:RemoveAllChildren()
    visibleNodes = {}
    talentsById = {}
    talentIndexById = {}

    local count = GetNumTalents(selectedTab - 1)
    for index = 0, count - 1 do
        local talent = GetTalentInfo(selectedTab - 1, index)
        talentsById[talent.id] = talent
        talentIndexById[talent.id] = index
    end

    for index = 0, count - 1 do
        local talent = GetTalentInfo(selectedTab - 1, index)
        local prerequisiteCount = GetNumTalentPrerequisites(selectedTab - 1, index)
        for prerequisiteIndex = 0, prerequisiteCount - 1 do
            local prerequisite = GetTalentPrerequisiteInfo(selectedTab - 1, index, prerequisiteIndex)
            local source = talentsById[prerequisite.talentId]
            if source ~= nil then
                TalentFrame_CreateLine(source, talent, prerequisite)
            end
        end
    end

    for index = 0, count - 1 do
        TalentFrame_CreateNode(GetTalentInfo(selectedTab - 1, index), index)
    end
end

function TalentFrame_Update(self)
    local tabCount = GetNumTalentTabs()
    if tabCount == 0 then
        selectedTab = 1
    elseif selectedTab > tabCount then
        selectedTab = tabCount
    end

    local player = GetUnit("player")
    playerTalentPoints = player and player:GetTalentPoints() or 0
    TalentFramePointsText:SetText(string.format(Localize("TALENT_POINTS_AVAILABLE"), playerTalentPoints))
    TalentFrame_UpdateTabs()
    TalentFrame_UpdateTalents()
end

function TalentFrameTalent_OnClick(self)
    local talentIndex = talentIndexById[self.id]
    if talentIndex == nil then
        return
    end
    local talent = GetTalentInfo(selectedTab - 1, talentIndex)
    if talent ~= nil and talent.canLearn then
        LearnTalent(selectedTab - 1, talentIndex)
    end
end

function TalentFrameTalent_OnEnter(self)
    local talentIndex = talentIndexById[self.id]
    if talentIndex == nil then
        return
    end
    local talent = GetTalentInfo(selectedTab - 1, talentIndex)
    if talent == nil or talent.spell == nil then
        return
    end

    GameTooltip:ClearAnchors()
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 12)
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0)
    GameTooltip_Clear()
    GameTooltip_AddLine(talent.spell.name, TOOLTIP_LINE_LEFT, "FFFFFFFF")
    GameTooltip_AddLine(string.format(Localize("TALENT_RANK_OF_MAX_RANK"), talent.rank, talent.maxRank), TOOLTIP_LINE_LEFT, "FFB8BEC8")
    GameTooltip_AddLine(GetSpellDescription(talent.spell), TOOLTIP_LINE_LEFT, "FFFFD100")

    if talent.rank < talent.maxRank and talent.rank > 0 and talent.nextRankSpell ~= nil then
        GameTooltip_AddLine("", TOOLTIP_LINE_LEFT, "FFFFFFFF")
        GameTooltip_AddLine(Localize("TALENT_NEXT_RANK"), TOOLTIP_LINE_LEFT, "FFFFFFFF")
        GameTooltip_AddLine(GetSpellDescription(talent.nextRankSpell), TOOLTIP_LINE_LEFT, "FFFFD100")
    end

    local spent = GetTalentPointsSpentInTab(selectedTab - 1)
    if spent < talent.requiredPoints then
        GameTooltip_AddLine("", TOOLTIP_LINE_LEFT, "FFFFFFFF")
        GameTooltip_AddLine(string.format(Localize("TALENT_REQUIRES_POINTS"), talent.requiredPoints, spent, talent.requiredPoints), TOOLTIP_LINE_LEFT, "FFFF6666")
    end
    local prerequisiteCount = GetNumTalentPrerequisites(selectedTab - 1, talentIndex)
    for prerequisiteIndex = 0, prerequisiteCount - 1 do
        local prerequisite = GetTalentPrerequisiteInfo(selectedTab - 1, talentIndex, prerequisiteIndex)
        if not prerequisite.met then
            local source = talentsById[prerequisite.talentId]
            local sourceName = source and source.name or tostring(prerequisite.talentId)
            GameTooltip_AddLine(string.format(Localize("TALENT_REQUIRES_TALENT"), sourceName, prerequisite.requiredRank, prerequisite.currentRank, prerequisite.requiredRank), TOOLTIP_LINE_LEFT, "FFFF6666")
        end
    end
    GameTooltip:Show()
end

function TalentFrameTalent_OnLeave(self)
    GameTooltip:Hide()
end

local function TalentFrameCanvas_OnMouseDown(self, button)
    -- Allow panning with either the left (1) or right (2) mouse button.
    if button == 1 or button == 2 then
        canvasDragging = true
        return true
    end
    return false
end

local function TalentFrameCanvas_OnMouseUp(self, button)
    canvasDragging = false
end

local function TalentFrameCanvas_OnMouseMove(self, x, y, deltaX, deltaY)
    if not canvasDragging then
        return
    end
    talentPanX = talentPanX + deltaX
    talentPanY = talentPanY + deltaY
    TalentFrame_ApplyView()
end

local function TalentFrameCanvas_OnMouseWheel(self, delta)
    TalentFrame_SetZoom(talentZoom * (delta > 0 and 1.12 or 0.89))
end

function TalentFrame_OnShow(self)
    TalentFrame_Update(self)
end

function TalentFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", TalentFrame_Update)
    self:RegisterEvent("PLAYER_LEVEL_UP", TalentFrame_Update)
    self:RegisterEvent("PLAYER_ENTER_WORLD", TalentFrame_Update)

    TalentFrameTitleBar:GetChild(0):SetClickedHandler(TalentFrame_Toggle)
    TalentFrameZoomOut:SetClickedHandler(function() TalentFrame_SetZoom(talentZoom - 0.1) end)
    TalentFrameZoomIn:SetClickedHandler(function() TalentFrame_SetZoom(talentZoom + 0.1) end)
    TalentFrameZoomReset:SetClickedHandler(function() TalentFrame_ResetView(); TalentFrame_UpdateTalents() end)
    TalentFrameCanvasViewport:SetOnMouseDownHandler(TalentFrameCanvas_OnMouseDown)
    TalentFrameCanvasViewport:SetOnMouseUpHandler(TalentFrameCanvas_OnMouseUp)
    TalentFrameCanvasViewport:SetOnMouseMoveHandler(TalentFrameCanvas_OnMouseMove)
    TalentFrameCanvasViewport:SetOnMouseWheelHandler(TalentFrameCanvas_OnMouseWheel)

    AddMenuBarButton("Interface/Icons/fg4_icons_emblemShield_result.htex", TalentFrame_Toggle)
    TalentFrame_ResetView()
end
