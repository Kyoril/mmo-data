
function ActionButton_OnEnter(self)

    local id = tonumber(self.id);
    if (id == nil) then
        self:Disable();
        return;
    end

    local spellIndex = id - 1;
    local spell = GetSpell(spellIndex);
    if (spell == nil) then
        return
    end

    GameTooltip:ClearAnchors()
    GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16)
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0)

    GameTooltip_SetSpell(spell)
    
    GameTooltip:Show()
end

function ActionButton_OnLeave(self)
    GameTooltip:Hide()
end

function ActionButton_Down(id)

    if (id == nil) then
        return;
    end

    if (id < 1 or id > 12) then
        return;
    end

    local button = _G["ActionButton"..id];
    button:SetButtonState(ButtonState.PUSHED);
end

function ActionButton_Up(id)

    if (id == nil) then
        return;
    end

    if (id < 1 or id > 12) then
        return;
    end

    local button = _G["ActionButton"..id];
    button:SetButtonState(ButtonState.NORMAL);

    ActionButton_OnClick(button);
end

function ActionButton_OnClick(self)
    local id = self.id;
    CastSpell(id - 1);
end

function ActionBar_UpdateButtons(self)
    -- Set up the 12 action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton"..i];

        local spell = GetSpell(i - 1);
        if (spell ~= nil) then
            button:SetProperty("Icon", spell.icon);
        end
    end
end

function ActionBar_OnLoad(self)
    self:RegisterEvent("SPELL_LEARNED", ActionBar_UpdateButtons);

    -- Set up the 12 action bar buttons
    for i = 1, 12 do
        local button = _G["ActionButton"..i];
        button:SetClickedHandler(ActionButton_OnClick);
        button:SetOnEnterHandler(ActionButton_OnEnter);
        button:SetOnLeaveHandler(ActionButton_OnLeave);
    end
end
