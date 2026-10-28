
-- Slots per bar and in total. Slots 1-12 are the main bar, 13-24 the second bar above it.
ACTION_BUTTONS_PER_BAR = 12;
MAX_ACTION_BUTTONS = 24;

-- Console variable deciding whether the second action bar is shown.
ACTION_BAR_2_CVAR = "ShowActionBar2";
ACTION_BAR_LOCK_CVAR = "LockActionBars";

ACTION_BAR_MOVE_BINDING = "MOVEACTIONBAR";
local actionBarMoveKeys = {};

function ActionBar_MoveKeyBinding(key, state)
	actionBarMoveKeys[key] = state ~= "UP";
end

function ActionBar_IsMoveKeyDown()
	for _, key in ipairs(GetKeysForBinding(ACTION_BAR_MOVE_BINDING) or {}) do
		-- Read modifiers directly so releasing one while a text field or menu has
		-- keyboard focus cannot leave the action bar unlocked.
		if key == "SHIFT" then
			if IsShiftKeyDown() then return true; end
		elseif key == "CONTROL" then
			if IsControlKeyDown() then return true; end
		elseif key == "ALT" then
			if IsAltKeyDown() then return true; end
		elseif actionBarMoveKeys[key] then
			local modifiersHeld = (not key:find("CTRL-", 1, true) or IsControlKeyDown())
				and (not key:find("SHIFT-", 1, true) or IsShiftKeyDown())
				and (not key:find("ALT-", 1, true) or IsAltKeyDown());
			if modifiersHeld then return true; end
		end
	end
	return false;
end

-- Gap (UI units) between the second bar and the experience bars below it, and between the second
-- bar and the player frame / cast bar it pushes up.
ACTION_BAR_2_GAP = 24;

-- Bottom offset of the player frame and cast bar while the second bar is hidden (matches the XML).
ACTION_BAR_2_HUD_DEFAULT_BOTTOM = -400;

-- Offset of the chat input above the menu bar while the second bar is hidden (matches the XML).
ACTION_BAR_2_CHAT_DEFAULT_BOTTOM = -24;

-- Tint used for the "active" glow shown on toggled ("Disabled While Active") spells such as Stealth.
ACTION_BUTTON_ACTIVE_GLOW = "FFFFD100";
ACTION_BUTTON_INACTIVE_GLOW = "00000000";

-- Socket tints of a bound slot, and of the translucent socket shown instead on empty second-bar slots.
ACTION_SOCKET_NORMAL_TINT = "FF998D7C";
ACTION_SOCKET_HOVERED_TINT = "FFFFFFFF";
ACTION_SOCKET_PUSHED_TINT = "FF91806A";
ACTION_EMPTY_SOCKET_TINT = "4D998D7C";
ACTION_EMPTY_SOCKET_HOVER_TINT = "A6FFFFFF";
ACTION_HIDDEN_TINT = "00000000";

-- Fallback icon for emotes without an authored icon.
EMOTE_FALLBACK_ICON = "Interface/Icons/fg4_iconsFlat_dialogue.htex";

-- Shows or hides the second action bar according to the interface option. Called on load and
-- whenever the option is toggled. The bar may be passed in explicitly, because its own OnLoad
-- runs before the frame is reachable through its global name.
function ActionBar_UpdateSecondBarVisibility(bar)
    bar = bar or ActionBar2;
    if bar == nil then
        return;
    end

    local value = GetCVar(ACTION_BAR_2_CVAR);
    if value ~= nil and value ~= "" and value ~= "0" then
        bar:Show();
    else
        bar:Hide();
    end

    ActionBar_UpdateSecondBarLayout(bar);
end

-- Stacks the second bar above the experience bars (or the menu bar plate when no experience bar
-- is shown) and, while it is visible, lifts the player frame, cast bar and chat above it. The chat
-- cluster reaches past the bar's left edge, and its frame would swallow the mouse over the first
-- slots. Called whenever the experience bar layout or the bar's visibility changes.
function ActionBar_UpdateSecondBarLayout(bar)
    bar = bar or ActionBar2;
    if bar == nil then
        return;
    end

    if ExperienceDock ~= nil and ExperienceDock:IsVisible() then
        bar:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, ExperienceDock, -ACTION_BAR_2_GAP);
    else
        bar:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, GameMenuBar, -ACTION_BAR_2_GAP);
    end

    -- The chat, player frame and cast bar load after the action bar, so they may not exist yet here.
    -- The chat cluster (log, scroll buttons) is anchored to the chat input and follows it.
    if ChatInputFrame ~= nil then
        if bar:IsVisible() then
            ChatInputFrame:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, bar, -ACTION_BAR_2_GAP);
        else
            ChatInputFrame:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, GameMenuBar, ACTION_BAR_2_CHAT_DEFAULT_BOTTOM);
        end
    end

    -- The target frame is anchored to the player frame and follows it.
    local hudFrames = { PlayerFrame, PlayerCastBar };
    for _, frame in ipairs(hudFrames) do
        if frame ~= nil then
            if bar:IsVisible() then
                frame:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, bar, -ACTION_BAR_2_GAP);
            else
                frame:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, ACTION_BAR_2_HUD_DEFAULT_BOTTOM);
            end
        end
    end
end

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
    elseif IsActionButtonEmote(self.id - 1) then
        local emote = GetActionButtonEmote(self.id - 1);
        if (emote ~= nil) then
            GameTooltip:ClearAnchors();
            GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
            GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);
            GameTooltip_SetEmote(emote);
            GameTooltip:Show();
        end
    end
end

function ActionBarButton_OnDrag(this, button, position)
    local locked = GetCVar(ACTION_BAR_LOCK_CVAR) or "1";
    if button == "LEFT" and (locked == "0" or locked == "false" or ActionBar_IsMoveKeyDown()) then
        PickupActionButton(this.id - 1);
    end
end

function ActionBarButton_OnDrop(this, button, position)
    if CursorHasPayload() then
        PickupActionButton(this.id - 1);
    end
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
    if (button == nil) then
        return;
    end

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
    if (button == nil) then
        return;
    end

    if (button:IsHovered()) then
        button:SetButtonState(ButtonState.HOVERED);
    else
        button:SetButtonState(ButtonState.NORMAL);
    end

    ActionButton_OnClick(button, "LEFT");
end

function ActionButton_OnClick(self, button)
    if (ActionBar_IsMoveKeyDown()) then
        PickupActionButton(self.id - 1);
    else
        UseActionButton(self.id - 1);
    end
end

function ActionBar_UpdateButtons(self)
    for i = 1, MAX_ACTION_BUTTONS do
        local button = _G["ActionButton"..i];
        if button ~= nil then

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
            elseif IsActionButtonEmote(i - 1) then
                local emote = GetActionButtonEmote(i - 1);

                if (emote ~= nil and emote.icon ~= "") then
                    button:SetProperty("Icon", emote.icon);
                else
                    button:SetProperty("Icon", EMOTE_FALLBACK_ICON);
                end
                button:SetText("");
            else
                -- Clear icon!
                button:SetProperty("Icon", "");
                button:SetText("");
                -- Main bar slots keep an opaque interior so terrain does not muddy the bar; empty
                -- second-bar slots switch to a translucent socket in ActionButton_UpdateSocketStyle.
            end

            -- Recompute the usable tint as well, so that changes which only affect usability
            -- (e.g. consuming the last item: count 1 -> 0) are reflected immediately.
            ActionButton_OnUpdate(button);
        end
    end
end

function ActionButton_OnUpdate(self)
    local usable = IsActionButtonUsable(self.id - 1);
    local occupied = IsActionButtonSpell(self.id - 1) or IsActionButtonItem(self.id - 1) or IsActionButtonEmote(self.id - 1);
    if usable or not occupied then
        self:SetProperty("Color", "FFFFFFFF");
    else
        self:SetProperty("Color", "FF888888");
    end

    ActionButton_UpdateSocketStyle(self, occupied);

    -- Toggle the "active" glow for spells that stay active while their aura persists (e.g. Stealth).
    if IsActionButtonActive(self.id - 1) then
        self:SetProperty("ActiveGlowTint", ACTION_BUTTON_ACTIVE_GLOW);
    else
        self:SetProperty("ActiveGlowTint", ACTION_BUTTON_INACTIVE_GLOW);
    end

    -- Update cooldown display
    ActionButton_UpdateCooldown(self);
end

-- The second bar floats over the world without a backing plate, so its empty slots draw a faint
-- translucent socket instead of the solid one. Main bar slots always keep the opaque socket.
function ActionButton_UpdateSocketStyle(self, occupied)
    if occupied or self.id <= ACTION_BUTTONS_PER_BAR then
        self:SetProperty("NormalFrameTint", ACTION_SOCKET_NORMAL_TINT);
        self:SetProperty("HoveredFrameTint", ACTION_SOCKET_HOVERED_TINT);
        self:SetProperty("PushedFrameTint", ACTION_SOCKET_PUSHED_TINT);
        self:SetProperty("EmptySocketTint", ACTION_HIDDEN_TINT);
        self:SetProperty("EmptySocketHoverTint", ACTION_HIDDEN_TINT);
    else
        self:SetProperty("NormalFrameTint", ACTION_HIDDEN_TINT);
        self:SetProperty("HoveredFrameTint", ACTION_HIDDEN_TINT);
        self:SetProperty("PushedFrameTint", ACTION_HIDDEN_TINT);
        self:SetProperty("EmptySocketTint", ACTION_EMPTY_SOCKET_TINT);
        self:SetProperty("EmptySocketHoverTint", ACTION_EMPTY_SOCKET_HOVER_TINT);
    end
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
        if button ~= nil then
            ActionButton_UpdateCooldown(button);
        end
    end
end

function ActionBar_OnLoad(self)
	RegisterBinding(ACTION_BAR_MOVE_BINDING, Localize("BINDING_MOVEACTIONBAR"), "ACTIONBAR",
		ActionBar_MoveKeyBinding, "SHIFT");

    self:RegisterEvent("SPELL_LEARNED", ActionBar_UpdateButtons);
    self:RegisterEvent("PLAYER_SPELLS_CHANGED", ActionBar_UpdateButtons);
    self:RegisterEvent("PLAYER_ENTER_WORLD", ActionBar_UpdateButtons);
    self:RegisterEvent("ACTION_BAR_CHANGED", ActionBar_UpdateButtons);
    
    self:RegisterEvent("LOOT_ITEM_RECEIVED", ActionBar_UpdateButtons);
    self:RegisterEvent("ITEM_RECEIVED", ActionBar_UpdateButtons);
    self:RegisterEvent("ITEM_CREATED", ActionBar_UpdateButtons);
    self:RegisterEvent("MEMBER_LOOT_ITEM_RECEIVED", ActionBar_UpdateButtons);
    self:RegisterEvent("MEMBER_ITEM_RECEIVED", ActionBar_UpdateButtons);
    
    -- Register for item count changes
    self:RegisterEvent("ITEM_COUNT_CHANGED", ActionBar_UpdateButtons);

    -- Register for cooldown events
    self:RegisterEvent("SPELL_COOLDOWN_STARTED", ActionBar_UpdateCooldowns);
    self:RegisterEvent("SPELL_COOLDOWN_ENDED", ActionBar_UpdateCooldowns);

    -- Refresh the active-state glow (and usability) whenever the player's auras change, e.g. when a
    -- toggled "Disabled While Active" spell such as Stealth is applied or fades.
    self:RegisterEvent("PLAYER_AURA_UPDATE", ActionBar_UpdateButtons);

    ActionBar_SetupButtons(1, ACTION_BUTTONS_PER_BAR);
end

-- Wires the handlers and per-button events of one bar's buttons.
function ActionBar_SetupButtons(firstId, lastId)
    for i = firstId, lastId do
        local button = _G["ActionButton"..i];
        if button ~= nil then
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
end

function ActionBar2_OnLoad(self)
    ActionBar_SetupButtons(ACTION_BUTTONS_PER_BAR + 1, MAX_ACTION_BUTTONS);

    -- The second bar loads after the main bar, so its buttons missed that bar's refresh.
    ActionBar_UpdateButtons(self);
    ActionBar_UpdateSecondBarVisibility(self);
end

-- Binding changes have no UI event; refresh these small captions once per second.
local shortcutRefreshElapsed = 1.0;
function ActionBar_UpdateShortcutLabels(elapsed)
    shortcutRefreshElapsed = shortcutRefreshElapsed + elapsed;
    if shortcutRefreshElapsed < 1.0 then
        return;
    end
    shortcutRefreshElapsed = 0;
    for i = 1, MAX_ACTION_BUTTONS do
        local keys = GetKeysForBinding("ACTIONBUTTON" .. i);
        local text = keys and keys[1] or "";
        text = text:gsub("CTRL%-", "C-"):gsub("SHIFT%-", "S-"):gsub("ALT%-", "A-");
        text = text:gsub("MINUS$", "-"):gsub("PLUS$", "+");
        local button = _G["ActionButton" .. i];
        if button ~= nil then
            button:GetChild(1):SetText(text);
        end
    end
end
