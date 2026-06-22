
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

        -- Recompute the usable tint as well, so that changes which only affect usability
        -- (e.g. consuming the last item: count 1 -> 0) are reflected immediately.
        ActionButton_OnUpdate(button);
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

-- Returns the spell that drives an item-type action button's cooldown, i.e. the item's
-- "On Use" spell, or nil if the item has no usable spell.
function ActionButton_GetItemUseSpell(slot)
    if not IsActionButtonItem(slot) then
        return nil;
    end

    local item = GetActionButtonItem(slot);
    if item == nil then
        return nil;
    end

    for i = 0, 4 do
        local spellId = item:GetSpellId(i);
        if spellId ~= 0 then
            if item:GetSpellTriggerType(i) == "ON_USE" then
                -- Resolve the spell entry by its id from the static game data. Note: the global
                -- GetSpell() resolves an index into the player's known spells, which would fail
                -- here because item-use spells are usually not in the player's spellbook.
                return GetItemSpell(item, i);
            end
        else
            break;
        end
    end

    return nil;
end

function ActionButton_UpdateCooldown(self)
    local cooldownFrame = self:GetChild(0);
    if cooldownFrame == nil then
        return;
    end

    -- Resolve the spell driving this button's cooldown. For spell buttons this is the spell
    -- itself; for item buttons it is the item's "On Use" spell (e.g. a potion's heal effect).
    local spell = nil;
    if IsActionButtonSpell(self.id - 1) then
        spell = GetActionButtonSpell(self.id - 1);
    elseif IsActionButtonItem(self.id - 1) then
        spell = ActionButton_GetItemUseSpell(self.id - 1);
    end

    if spell ~= nil and IsSpellOnCooldown(spell.id) then
        local progress = GetSpellCooldownProgress(spell.id);
        cooldownFrame:SetProgress(progress);
        cooldownFrame:Show();
    else
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
        button:SetOnDragHandler(ActionBarButton_OnDrag);
        button:SetOnDropHandler(ActionBarButton_OnDrop);

        button:RegisterEvent("PLAYER_POWER_CHANGED", ActionButton_OnUpdate);
        button:RegisterEvent("ACTION_BAR_CHANGED", ActionButton_OnUpdate);

        ActionButton_OnUpdate(button);
    end
end
