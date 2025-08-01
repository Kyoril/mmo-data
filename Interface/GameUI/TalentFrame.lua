
-- Constants
MAX_TALENT_TABS = 3
MAX_TALENTS_PER_TAB = 20
MAX_TALENT_TIERS = 7
MAX_TALENTS_PER_TIER = 4
MAX_TALENT_RANK = 5

-- Keep track of which tab is selected
local selectedTab = 1
local playerTalentPoints = 0
local talentAvailable = false

function TalentFrame_Toggle()
    if (TalentFrame:IsVisible()) then
        HideUIPanel(TalentFrame);
    else
        ShowUIPanel(TalentFrame);
    end
end

function TalentFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Set title
    self:GetChild(0):SetText(Localize("TALENTS"));
    
    -- Register events
    self:RegisterEvent("PLAYER_TALENT_UPDATE", TalentFrame_Update);
    self:RegisterEvent("PLAYER_LEVEL_UP", TalentFrame_Update);
    self:RegisterEvent("PLAYER_ENTER_WORLD", TalentFrame_Update);
    
    -- Clear talent display first
    for i=1, MAX_TALENTS_PER_TAB do
        local button = _G["TalentFrameTalent"..i];
        button:SetOnEnterHandler(TalentFrameTalent_OnEnter);
        button:SetOnLeaveHandler(TalentFrameTalent_OnLeave);
        button:SetClickedHandler(TalentFrameTalent_OnClick);
    end

    -- Add button to menu bar
    AddMenuBarButton("Interface/Icons/fg4_icons_emblemShield_result.htex", TalentFrame_Toggle);
end

function TalentFrame_OnShow(self)
    TalentFrame_Update(self);
end

function TalentFrame_Update(self)
    -- Update and display tab information
    TalentFrame_UpdateTabs();
    
    -- Update talents for the selected tab
    TalentFrame_UpdateTalents();
end

function TalentFrame_UpdateTabs()
    -- Get the class tabs info
    local numTabs = GetNumTalentTabs();
    
    -- Show/hide the tabs based on availability
    for i=1, MAX_TALENT_TABS do
        local tabButton = _G["TalentFrameTab"..i];
        
        if (i <= numTabs) then
            local tabInfo = GetTalentTabName(i - 1);
            tabButton:SetText(tabInfo);
            tabButton:Show();
              -- Highlight selected tab
            if (i == selectedTab) then
                tabButton:SetChecked(true);
            else
                tabButton:SetChecked(false);
            end
        else
            -- Hide unused tabs
            tabButton:Hide();
        end
    end
end

function TalentFrameTab_OnClick(self)
    local id = self.id;

    if (id ~= selectedTab) then
        selectedTab = id;
        TalentFrame_Update(TalentFrame);
    end
end

function TalentFrame_UpdateTalents()
    -- Update talent point display
    local player = GetUnit("player");
    playerTalentPoints = player:GetTalentPoints() or 0;
    TalentFramePointsText:SetText(string.format(Localize("TALENT_POINTS_AVAILABLE"), playerTalentPoints));

    -- Get the talents for the selected tab
    local numTalents = GetNumTalents(selectedTab - 1);
    
    TalentFrameScrollBar:SetMinimum(0);
    TalentFrameScrollBar:SetMaximum(0);

    local pointsSpent = GetTalentPointsSpentInTab(selectedTab - 1);
    
    -- Clear talent display first
    for i=1, MAX_TALENTS_PER_TAB do
        local button = _G["TalentFrameTalent"..i];
        button:Hide();
    end
    
    -- Display the talents
    for i=1, numTalents do
        local talent = GetTalentInfo(selectedTab - 1, i - 1);

        -- Calculate button index from tier and column
        local index = (talent.tier * MAX_TALENTS_PER_TIER) + talent.column + 1;
        local button = _G["TalentFrameTalent"..index];
        
        button.id = i;
        button.tabID = selectedTab - 1;
        button.tier = talent.tier;
        button.column = talent.column;
        button.spell = talent.spell;        
        
        -- For each tier, 5 points spent are required to unlock the next tier, so make the button appear disabled if not enough points spent
        if (talent.tier > 0 and pointsSpent < (talent.tier * 5)) then
            -- Make button appear disabled but keep it enabled for mouse events
            button:SetOpacity(0.4);  -- 40% opacity to show as disabled
            button.isDisabled = true;  -- Track disabled state for click handling
        else
            -- Button is available
            button:SetOpacity(1.0);  -- Full opacity
            button.isDisabled = false;  -- Track enabled state
        end
        
        -- Set the icon
        button:SetProperty("Icon", talent.icon or "");        -- Set the rank overlay
        local rankFrame = _G["TalentFrameTalent"..index.."_Rank"];
        if rankFrame then
            -- Hide rank frame for unavailable talents, show for available ones
            if (button.isDisabled) then
                rankFrame:Hide();
            else
                rankFrame:Show();
                -- Show only current rank instead of current/max
                rankFrame:SetText(string.format("%d", talent.rank));
                
                -- Color the rank text based on talent state
                if (talent.rank == talent.maxRank) then
                    -- Max rank - yellow/orange
                    rankFrame:SetProperty("TextColor", "FFFFD100");  -- Orange/yellow for max rank
                elseif (playerTalentPoints > 0 and talent.rank < talent.maxRank) then
                    -- Can be trained - green
                    rankFrame:SetProperty("TextColor", "FF33FF33");  -- Green for available
                else
                    -- Cannot be trained - white/grey
                    rankFrame:SetProperty("TextColor", "FFCCCCCC");  -- Light grey for unavailable
                end
            end
        end
        
        -- Color the talent based on whether it can be trained
        talentAvailable = false;--CanTrainTalent(talent, playerTalentPoints)
        if (talent.rank == talent.maxRank) then
            -- Max rank, show as normal
            --button:SetState("Normal")
        elseif (talentAvailable) then
            -- Available to train
            --button:SetState("Highlighted")
        else
            -- Not available to train
            --button:SetState("Disabled")
        end
        
        -- Show the button
        button:Show();
        
        -- Update branch lines
        TalentFrame_UpdateBranches(button, talent);
    end
end

function TalentFrame_UpdateBranches(button, talent)
    -- Update the arrow connections between talents based on prerequisites
    if not talent.prerequisite then return end;
    
    -- Find parent button
    local parentButton = nil;
    for i=1, MAX_TALENTS_PER_TAB do
        local possibleParent = _G["TalentFrameTalent"..i]
        if (possibleParent.id == talent.prerequisite) then;
            parentButton = possibleParent;
            break;
        end
    end
    
    if not parentButton then return end;
    
    -- Calculate positions
    local left = min(button.column, parentButton.column);
    local right = max(button.column, parentButton.column);
    local top = min(button.tier, parentButton.tier);
    local bottom = max(button.tier, parentButton.tier);
    local horizontalDistance = right - left;
    local verticalDistance = bottom - top;
    
    -- Setup branch graphics here between interconnected talents
    if horizontalDistance > 0 and verticalDistance > 0 then
        -- Diagonal connections
    elseif horizontalDistance > 0 then
        -- Horizontal connections
    else
        -- Vertical connections
    end
end

function TalentFrameTalent_OnClick(self)
    -- Check if button is visually disabled
    if (self.isDisabled) then
        return; -- Don't allow clicking on disabled talents
    end
    
    if (playerTalentPoints > 0) then
        local talentID = self.id;
        local tabID = selectedTab - 1;
        
        -- Learn the talent (in a real implementation, this would call server)
        local result = LearnTalent(tabID, talentID - 1)
        
        if (result) then
            -- Update display after learning
            TalentFrame_Update(TalentFrame);
        end
    end
end

function TalentFrameTalent_OnEnter(self)
    local talentID = self.id;
    local talent = GetTalentInfo(selectedTab - 1, talentID - 1);

    if not talent then
        return
    end;

    -- Provide visual feedback for disabled talents
    if (self.isDisabled) then
        -- Slightly brighten disabled talents on hover for better feedback
        self:SetProperty("Alpha", "0.6");  -- Increase from 40% to 60% opacity on hover
    end

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, self, 0);

    local player = GetUnit("player");
    GameTooltip_Clear();

    if (talent.spell == nil) then
        return
    end    
    
    GameTooltip_AddLine(talent.spell.name, TOOLTIP_LINE_LEFT, "FFFFFFFF");
    GameTooltip_AddLine(string.format(Localize("TALENT_RANK_OF_MAX_RANK"), talent.rank, talent.maxRank), TOOLTIP_LINE_LEFT, "FFFFFFFF");
    GameTooltip_AddLine(GetSpellDescription(talent.spell), TOOLTIP_LINE_LEFT, "FFFFD100");

    -- Show next rank information if available
    if (talent.rank < talent.maxRank and talent.rank > 0 and talent.nextRankSpell) then
        GameTooltip_AddLine("", TOOLTIP_LINE_LEFT, "FFFFFFFF");
        GameTooltip_AddLine(Localize("TALENT_NEXT_RANK"), TOOLTIP_LINE_LEFT, "FFFFFFFF");
        GameTooltip_AddLine(GetSpellDescription(talent.nextRankSpell), TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    -- Show requirement information if talent is disabled
    if (self.isDisabled) then
        local pointsSpent = GetTalentPointsSpentInTab(selectedTab - 1);
        local requiredPoints = talent.tier * 5;
        GameTooltip_AddLine("", TOOLTIP_LINE_LEFT, "FFFFFFFF");
        GameTooltip_AddLine(string.format("Requires %d points in this talent tree (%d/%d)", requiredPoints, pointsSpent, requiredPoints), TOOLTIP_LINE_LEFT, "FFFF5555");
    end

    GameTooltip:Show();
end

function TalentFrameTalent_OnLeave(self)
    GameTooltip:Hide();
    
    -- Restore original alpha state for disabled talents
    if (self.isDisabled) then
        self:SetOpacity(0.4);  -- Restore to 40% opacity when not hovering
    end
end
