
function TrainerFrame_OnTrainerShow(self)
    ShowUIPanel(self);
end

function TrainerFrame_OnTrainerUpdate(self)
    
end

function TrainerFrame_OnTrainerClosed(self)
    HideUIPanel(self);
end

function TrainerBuyButton_OnClick(self)
    if TrainerFrame.selectedSpellIndex then
        BuyTrainerSpell(TrainerFrame.selectedSpellIndex);
    end
end

function TrainerFrame_CanBuySpell(trainerSpellIndex)
    if not trainerSpellIndex then
        return false;
    end

    -- Get trainer spell cost
    local spellId, spellName, spellIcon, cost = GetTrainerSpellInfo(trainerSpellIndex);
    if spellId < 0 then
        -- Can't buy because spell doesn't exist
        return false;
    end

    local money = UnitMoney("player");
    if money < cost then
        -- Can't buy because not enough money
        return false;
    end

    -- TODO: Level check

    return true;
end

function TrainerSpellButton_OnClick(item)
	-- For each button in characterButtons, call SetChecked(false)
    local maxVisibleItems = TrainerSpellListContent:GetChildCount();
    for i = 1, maxVisibleItems do
		TrainerSpellListContent:GetChild(i - 1):SetChecked(false);
	end

    -- Ensure list item is checked
	item:SetChecked(true);

    local spellId, spellName, spellIcon, cost = GetTrainerSpellInfo(item.id - 1);
    if spellId > 0 then
        TrainerSpellPreviewButton:SetProperty("Icon", spellIcon);
        TrainerSpellPreviewName:SetText(spellName);
        TrainerSpellPreviewButton.userData = gameData.spells:GetById(spellId);
        TrainerSpellDescriptionText:SetText(GetSpellDescription(TrainerSpellPreviewButton.userData));
        RefreshMoneyFrame("TrainerSpellCostMoney", cost, false, false, true);

        TrainerFrame.selectedSpellIndex = item.id - 1;
        TrainerSpellDescContent:Show();
    else
        TrainerFrame.selectedSpellIndex = nil;
        TrainerSpellDescContent:Hide();
    end
    
    -- TODO: Apply scroll offset to item id
    if TrainerFrame_CanBuySpell(item.id - 1) then
        TrainerBuyButton:Enable();
    else
        TrainerBuyButton:Disable();
    end
end

function TrainerFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);

    TrainerSpellCostLabel:SetWidth(TrainerSpellCostLabel:GetTextWidth());
    TrainerSpellPreviewButton:SetOnEnterHandler(function(button)
        GameTooltip:ClearAnchors();
        GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, button, 0);
        GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, button, 16);
        GameTooltip_SetSpell(button.userData);
        GameTooltip:Show();
    end);
    TrainerSpellPreviewButton:SetOnLeaveHandler(function(button)
        GameTooltip:Hide();
    end);

    -- Register for trainer events
    self:RegisterEvent("TRAINER_SHOW", TrainerFrame_OnTrainerShow);
    self:RegisterEvent("TRAINER_UPDATE", TrainerFrame_OnTrainerUpdate);
    self:RegisterEvent("TRAINER_CLOSED", TrainerFrame_OnTrainerClosed);
end

function TrainerFrame_OnShow(self)
    local target = GetUnit("target");
    if target then
        self:GetChild(0):SetText(target:GetName());
    end

    -- Reset preview
    TrainerSpellDescContent:Hide();
    TrainerBuyButton:Disable();
    TrainerFrame.selectedSpellId = nil;

    local numTrainerSpells = GetNumTrainerSpells();

    -- Load vendor spells
    local maxVisibleItems = TrainerSpellListContent:GetChildCount();
    for i = 1, maxVisibleItems do
        local item = TrainerSpellListContent:GetChild(i - 1);
        if not item then
            break;
        end

        if i <= numTrainerSpells then
            local spellId, spellName, spellIcon, cost = GetTrainerSpellInfo(i - 1);
            item:SetText(spellName);
            item:Show();
        else
            item:Hide();
        end
    end

    local money = UnitMoney("player");
    RefreshMoneyFrame("TrainerPlayerMoneyFrame", money, false, false, true);
end

function TrainerFrame_Toggle()
    if TrainerFrame:IsVisible() then
        HideUIPanel(TrainerFrame);
    else
        ShowUIPanel(TrainerFrame);
    end
end
