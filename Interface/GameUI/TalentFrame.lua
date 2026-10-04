local selectedTab = 1
local playerTalentPoints = 0
local talentZoom = 1.0
local talentPanX = 0.0
local talentPanY = 0.0
local canvasDragging = false
local viewInitialized = false
local visibleNodes = {}
local talentsById = {}
local talentIndexById = {}

local TALENT_NODE_SIZE = 128
local TALENT_HUB_SIZE = 190
local TALENT_MIN_ZOOM = 0.35
local TALENT_MAX_ZOOM = 1.60

-- Canvas units the constellation backdrop covers from the hub to its left/right and top/bottom
-- edges. Must match BACKDROP_RADIUS * STRETCH and BACKDROP_RADIUS in
-- tools/talent_trees/make_backdrop.py, or the rings miss the nodes.
local TALENT_BACKDROP_HALF_WIDTH = 1204
local TALENT_BACKDROP_HALF_HEIGHT = 860

-- Visual states for a talent node, used to convey at a glance whether a talent
-- can be spent into right now.
--   "maxed"       - fully ranked, nothing more to spend
--   "available"   - learnable right now (points available + requirements met)
--   "nopoints"    - requirements met, but no talent points left to spend
--   "blocked"     - requirements not met yet (missing prerequisites / required points)
--   "placeholder" - a planned talent that can not be learned yet
-- Unavailable nodes are pushed dark and cold so they recede; the only nodes that
-- read as "warm / colorful" are the ones you can actually act on. Available nodes
-- additionally get a green glow halo so they pop out at a glance.
local TALENT_ICON_TINT = {
    maxed = "FFFFFFFF",
    available = "FFFFFFFF",
    nopoints = "FF5A6470",
    blocked = "FF454C57",
    placeholder = "FF3A3E46",
}
local TALENT_NODE_OPACITY = {
    maxed = 1.0,
    available = 1.0,
    nopoints = 0.85,
    blocked = 0.75,
    placeholder = 0.55,
}
local TALENT_GLOW_TINT = {
    maxed = "00000000",
    available = "FF3BE07A",
    nopoints = "00000000",
    blocked = "00000000",
    placeholder = "00000000",
}
local TALENT_RANK_COLOR = {
    maxed = "FFFFD100",
    available = "FF42E67A",
    nopoints = "FFA0A8B2",
    blocked = "FF7A828E",
    placeholder = "FF7A828E",
}

-- Link colors. Paths use the talent's accent color; these are the fallbacks.
local TALENT_LINE_COLOR_DEFAULT = "FFC1A56C"
local TALENT_LINE_COLOR_PLACEHOLDER = "FF8A8F99"
local TALENT_COMING_SOON_COLOR = "FF8FB8FF"

-- Replaces the alpha byte of an "AARRGGBB" color string.
local function TalentFrame_WithAlpha(color, alpha)
    return alpha .. string.sub(color, 3)
end

local function TalentFrame_GetSelectedTabInfo()
    return GetTalentTabInfo(selectedTab - 1)
end

-- Viewport size in UI units. GetRect() resolves the layout on demand, whereas GetWidth()
-- reads ~0 until the frame was laid out once (e.g. while the window was never shown).
local function TalentFrame_GetViewportSize()
    local rect = TalentFrameCanvasViewport:GetRect()
    return (rect.right - rect.left) / GetUIScale().x, (rect.bottom - rect.top) / GetUIScale().y
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

    local viewportWidth, viewportHeight = TalentFrame_GetViewportSize()
    if viewportWidth <= 0 or viewportHeight <= 0 then
        -- Not laid out yet; TalentFrame_OnShow resets the view once it is.
        return
    end

    talentZoom = math.max(TALENT_MIN_ZOOM, math.min(TALENT_MAX_ZOOM, tab.initialZoom))
    talentPanX = (viewportWidth - tab.canvasWidth * talentZoom) * 0.5
    talentPanY = (viewportHeight - tab.canvasHeight * talentZoom) * 0.5
    viewInitialized = true
    TalentFrame_ApplyView()
end

local function TalentFrame_SetZoom(newZoom)
    local oldZoom = talentZoom
    newZoom = math.max(TALENT_MIN_ZOOM, math.min(TALENT_MAX_ZOOM, newZoom))
    if math.abs(newZoom - oldZoom) < 0.001 then
        return
    end

    local viewportWidth, viewportHeight = TalentFrame_GetViewportSize()
    local centerX = viewportWidth * 0.5
    local centerY = viewportHeight * 0.5
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
    -- The container is anchor-sized, so GetWidth() is only valid once its rect was laid out;
    -- before the first show it reads ~0 and the tab collapsed. GetRect() resolves on demand.
    local rect = TalentFrameTabContainer:GetRect()
    local containerWidth = (rect.right - rect.left) / GetUIScale().x
    if containerWidth <= 0 then
        containerWidth = 360 * math.max(1, count)
    end
    local tabWidth = math.min(360, containerWidth / math.max(1, count))
    local startX = 0

    for index = 1, count do
        local tab = GetTalentTabInfo(index - 1)
        local button = TalentFrameTabButtonTemplate:Clone()
        button.id = index
        button:SetWidth(tabWidth - 8)
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

-- Adds one straight line between two canvas points (in canvas units).
local function TalentFrame_AddLine(startX, startY, endX, endY, thickness, color, frameLevel)
    local line = TalentFrameLineTemplate:Clone()
    line:SetSize(TalentFrameCanvasContent:GetWidth(), TalentFrameCanvasContent:GetHeight())
    line:ClearAnchors()
    line:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0)
    line:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0)
    line:SetProperty("StartX", tostring(startX * talentZoom))
    line:SetProperty("StartY", tostring(startY * talentZoom))
    line:SetProperty("EndX", tostring(endX * talentZoom))
    line:SetProperty("EndY", tostring(endY * talentZoom))
    line:SetProperty("Thickness", tostring(thickness * talentZoom))
    line:SetProperty("Color", color)
    line:SetFrameLevel(frameLevel)
    TalentFrameCanvasContent:AddChild(line)
end

-- A link along a path. Lit links get a soft glow under a bright core, so a learned path
-- reads as a glowing trail; unlit links stay thin in a dimmed path color, and links into a
-- placeholder are thin grey.
local function TalentFrame_AddLink(startX, startY, endX, endY, color, lit, toPlaceholder)
    if toPlaceholder then
        TalentFrame_AddLine(startX, startY, endX, endY, 3, TalentFrame_WithAlpha(TALENT_LINE_COLOR_PLACEHOLDER, "50"), 2)
    elseif lit then
        TalentFrame_AddLine(startX, startY, endX, endY, 22, TalentFrame_WithAlpha(color, "45"), 1)
        TalentFrame_AddLine(startX, startY, endX, endY, 7, color, 2)
    else
        TalentFrame_AddLine(startX, startY, endX, endY, 4, TalentFrame_WithAlpha(color, "70"), 2)
    end
end

local function TalentFrame_GetAccentColor(talent)
    if talent.accentColor ~= nil and talent.accentColor ~= "" then
        return talent.accentColor
    end
    return TALENT_LINE_COLOR_DEFAULT
end

-- Determines the visual state of a talent node (see TALENT_ICON_TINT above).
-- Note: talent.canLearn already bundles "points available + rank < maxRank +
-- required points spent + prerequisites met", so when it is false we recompute
-- the requirements here to tell apart "merely out of points" from "blocked".
local function TalentFrame_GetNodeState(talent, talentIndex)
    if talent.placeholder then
        return "placeholder"
    end
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
    if state == "placeholder" then
        rank:Hide()
    else
        rank:SetText(string.format("%d/%d", talent.rank, talent.maxRank))
        rank:SetProperty("TextColor", TALENT_RANK_COLOR[state])
    end

    TalentFrameCanvasContent:AddChild(button)
    visibleNodes[talent.id] = button
end

-- Backdrop, hub emblem and path labels of a tab with a hub.
local function TalentFrame_CreateConstellation(tab)
    local backdrop = TalentFrameBackdropTemplate:Clone()
    backdrop:SetSize(TALENT_BACKDROP_HALF_WIDTH * 2 * talentZoom, TALENT_BACKDROP_HALF_HEIGHT * 2 * talentZoom)
    backdrop:ClearAnchors()
    backdrop:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, (tab.hubY - TALENT_BACKDROP_HALF_HEIGHT) * talentZoom)
    backdrop:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, (tab.hubX - TALENT_BACKDROP_HALF_WIDTH) * talentZoom)
    backdrop:SetFrameLevel(0)
    TalentFrameCanvasContent:AddChild(backdrop)

    local hub = TalentFrameHubTemplate:Clone()
    local hubSize = TALENT_HUB_SIZE * talentZoom
    hub:SetSize(hubSize, hubSize)
    hub:ClearAnchors()
    hub:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, tab.hubY * talentZoom - hubSize * 0.5)
    hub:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, tab.hubX * talentZoom - hubSize * 0.5)
    hub:SetProperty("Icon", tab.icon or "")
    hub:SetFrameLevel(8)
    TalentFrameCanvasContent:AddChild(hub)

    local labelCount = GetNumTalentTabLabels(selectedTab - 1)
    for labelIndex = 0, labelCount - 1 do
        local info = GetTalentTabLabelInfo(selectedTab - 1, labelIndex)
        local label = TalentFrameLabelTemplate:Clone()
        local width = 420 * talentZoom
        local height = 60 * talentZoom
        label:SetSize(width, height)
        label:ClearAnchors()
        label:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, info.y * talentZoom - height * 0.5)
        label:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, info.x * talentZoom - width * 0.5)
        label:SetText(Localize(info.text))
        label:SetProperty("TextColor", info.color)
        label:SetFrameLevel(8)
        TalentFrameCanvasContent:AddChild(label)
    end
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

    if tab.hasHub then
        TalentFrame_CreateConstellation(tab)
    end

    for index = 0, count - 1 do
        local talent = GetTalentInfo(selectedTab - 1, index)
        local color = TalentFrame_GetAccentColor(talent)
        local prerequisiteCount = GetNumTalentPrerequisites(selectedTab - 1, index)
        if prerequisiteCount == 0 and tab.hasHub then
            -- Spoke from the class emblem to a root talent; lit once the root is learned.
            TalentFrame_AddLink(tab.hubX, tab.hubY, talent.positionX, talent.positionY, color, talent.rank > 0, talent.placeholder)
        end
        for prerequisiteIndex = 0, prerequisiteCount - 1 do
            local prerequisite = GetTalentPrerequisiteInfo(selectedTab - 1, index, prerequisiteIndex)
            local source = talentsById[prerequisite.talentId]
            if source ~= nil then
                local lit = prerequisite.met and talent.rank > 0
                TalentFrame_AddLink(source.positionX, source.positionY, talent.positionX, talent.positionY, color, lit, talent.placeholder)
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
    TalentFramePointsText:SetText(Localize("TALENT_POINTS_LABEL"))
    TalentFramePointsCounter:SetText(tostring(playerTalentPoints))
    TalentFramePointsCounter:SetProperty("TextColor", playerTalentPoints > 0 and "FFF3CF50" or "FF99958C")
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
    if talent.placeholder then
        GameTooltip_AddLine(Localize("TALENT_COMING_SOON"), TOOLTIP_LINE_LEFT, TALENT_COMING_SOON_COLOR)
        GameTooltip_AddLine(GetSpellDescription(talent.spell), TOOLTIP_LINE_LEFT, "FFB8BEC8")
        GameTooltip:Show()
        return
    end

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
    -- The view can only be centered once the viewport has a size, which it may not have
    -- had at load time.
    if not viewInitialized then
        TalentFrame_ResetView()
    end
    TalentFrame_Update(self)
end

function TalentFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", TalentFrame_Update)
    self:RegisterEvent("PLAYER_LEVEL_UP", TalentFrame_Update)
    self:RegisterEvent("PLAYER_ENTER_WORLD", function(frame)
        -- Another character may use another class with another canvas.
        viewInitialized = false
        TalentFrame_Update(frame)
    end)

    TalentFrameTitleBar:GetChild(0):SetClickedHandler(TalentFrame_Toggle)
    TalentFrameZoomOut:SetClickedHandler(function() TalentFrame_SetZoom(talentZoom - 0.1) end)
    TalentFrameZoomIn:SetClickedHandler(function() TalentFrame_SetZoom(talentZoom + 0.1) end)
    TalentFrameZoomReset:SetClickedHandler(function() TalentFrame_ResetView(); TalentFrame_UpdateTalents() end)
    TalentFrameCanvasViewport:SetOnMouseDownHandler(TalentFrameCanvas_OnMouseDown)
    TalentFrameCanvasViewport:SetOnMouseUpHandler(TalentFrameCanvas_OnMouseUp)
    TalentFrameCanvasViewport:SetOnMouseMoveHandler(TalentFrameCanvas_OnMouseMove)
    TalentFrameCanvasViewport:SetOnMouseWheelHandler(TalentFrameCanvas_OnMouseWheel)

    AddMenuBarButton("Interface/GameUI/Alestia/MenuIcons/Talents.htex", TalentFrame_Toggle, "MENUBAR_TOOLTIP_TALENTS", "TOGGLETALENTS")
    TalentFrame_ResetView()
end
