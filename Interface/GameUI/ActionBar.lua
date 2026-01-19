
MAX_ACTION_BUTTONS = 12;

function ActionButton_OnEnter(self)
    if IsActionButtonSpell(self.id - 1) then
        local spell = GetActionButtonSpell(self.id - 1);
        if (spell ~= nil) then
            GameTooltip:ClearAnchors();
            GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
            GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);
            GameTooltip_SetSpell(spell);
            GameTooltip:Show();
        end
    elseif IsActionButtonItem(self.id - 1) then
        local item = GetActionButtonItem(self.id - 1);
        if (item ~= nil) then
            GameTooltip:ClearAnchors();
            GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
            GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);
            GameTooltip_SetItemTemplate(item);
            GameTooltip:Show();
        end
    end
end

function ActionBarButton_OnDrag(this, button, position)
    PickupActionButton(this.id - 1);
end

function ActionBarButton_OnDrop(this, button, position)
    PickupActionButton(this.id - 1);
end

function ActionButton_OnLeave(self)
    GameTooltip:Hide();
end

function ActionButton_Down(id)
    if (id == nil) then
        return;
    end

    if (id < 1 or id > MAX_ACTION_BUTTONS) then
        return;
    end

    local button = _G["ActionButton"..id];
    button:SetButtonState(ButtonState.PUSHED);
end

function ActionButton_Up(id)
    if (id == nil) then
        return;
    end

    if (id < 1 or id > MAX_ACTION_BUTTONS) then
        return;
    end

    local button = _G["ActionButton"..id];
    button:SetButtonState(ButtonState.NORMAL);

    ActionButton_OnClick(button, "LEFT");
end

function ActionButton_OnClick(self, button)
    if (IsShiftKeyDown()) then
        PickupActionButton(self.id - 1);
    else
        UseActionButton(self.id - 1);
    end
end

function ActionBar_UpdateButtons(self)
    for i = 1, MAX_ACTION_BUTTONS do
        local button = _G["ActionButton"..i];

        button:SetOpacity(1.0);
        
        if IsActionButtonSpell(i - 1) then
            local spell = GetActionButtonSpell(i - 1);
            if (spell ~= nil) then
                button:SetProperty("Icon", spell.icon);
            else
                button:SetProperty("Icon", "");
            end

            button:SetText("");
        elseif IsActionButtonItem(i - 1) then
            local item = GetActionButtonItem(i - 1);

            if (item ~= nil) then
                button:SetProperty("Icon", item.GetIcon(item));
                
                local itemCount = GetItemCount(item.id);
                button:SetText(tostring(itemCount));
            else
                button:SetProperty("Icon", "");
                button:SetText("");
            end
        else
            -- Clear icon!
            button:SetProperty("Icon", "");
            button:SetText("");
            button:SetOpacity(0.5);
        end
    end
end

function ActionButton_OnUpdate(self)
    local usable = IsActionButtonUsable(self.id - 1);
    if usable then
        self:SetProperty("Color", "FFFFFFFF");
    else
        self:SetProperty("Color", "FF888888");
    end

    -- Update cooldown display
    ActionButton_UpdateCooldown(self);
end

function ActionButton_UpdateCooldown(self)
    local cooldownFrame = self:GetChild(0);
    if cooldownFrame == nil then
        return;
    end

    -- Check if this action button has a spell with a cooldown
    if IsActionButtonSpell(self.id - 1) then
        local spell = GetActionButtonSpell(self.id - 1);
        if spell ~= nil and IsSpellOnCooldown(spell.id) then
            local progress = GetSpellCooldownProgress(spell.id);
            cooldownFrame:SetProgress(progress);
            cooldownFrame:Show();
        else
            cooldownFrame:SetProgress(1.0);
            cooldownFrame:Hide();
        end
    else
        -- No spell, hide cooldown
        cooldownFrame:SetProgress(1.0);
        cooldownFrame:Hide();
    end
end

function ActionBar_UpdateCooldowns()
    for i = 1, MAX_ACTION_BUTTONS do
        local button = _G["ActionButton"..i];
        ActionButton_UpdateCooldown(button);
    end
end

function ActionBar_OnLoad(self)
    self:RegisterEvent("SPELL_LEARNED", ActionBar_UpdateButtons);
    self:RegisterEvent("PLAYER_SPELLS_CHANGED", ActionBar_UpdateButtons);
    self:RegisterEvent("PLAYER_ENTER_WORLD", ActionBar_UpdateButtons);
    self:RegisterEvent("ACTION_BAR_CHANGED", ActionBar_UpdateButtons);
    
    self:RegisterEvent("LOOT_ITEM_RECEIVED", ActionBar_UpdateButtons);
    self:RegisterEvent("ITEM_RECEIVED", ActionBar_UpdateButtons);
    self:RegisterEvent("MEMBER_LOOT_ITEM_RECEIVED", ActionBar_UpdateButtons);
    self:RegisterEvent("MEMBER_ITEM_RECEIVED", ActionBar_UpdateButtons);
    
    -- Register for item count changes
    self:RegisterEvent("ITEM_COUNT_CHANGED", ActionBar_UpdateButtons);

    -- Register for cooldown events
    self:RegisterEvent("SPELL_COOLDOWN_STARTED", ActionBar_UpdateCooldowns);
    self:RegisterEvent("SPELL_COOLDOWN_ENDED", ActionBar_UpdateCooldowns);

    for i = 1, MAX_ACTION_BUTTONS do
        local button = _G["ActionButton"..i];
        button:SetClickedHandler(ActionButton_OnClick);
        button:SetOnEnterHandler(ActionButton_OnEnter);
        button:SetOnLeaveHandler(ActionButton_OnLeave);

        button:RegisterEvent("PLAYER_POWER_CHANGED", ActionButton_OnUpdate);
        button:RegisterEvent("ACTION_BAR_CHANGED", ActionButton_OnUpdate);

        ActionButton_OnUpdate(button);
    end
end
