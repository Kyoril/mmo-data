
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
end

function ActionBar_OnLoad(self)
    self:RegisterEvent("SPELL_LEARNED", ActionBar_UpdateButtons);
    self:RegisterEvent("PLAYER_SPELLS_CHANGED", ActionBar_UpdateButtons);
    self:RegisterEvent("PLAYER_ENTER_WORLD", ActionBar_UpdateButtons);
    self:RegisterEvent("ACTION_BAR_CHANGED", ActionBar_UpdateButtons);

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
