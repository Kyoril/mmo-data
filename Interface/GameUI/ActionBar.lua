
-- Slots per bar and in total. Slots 1-12 are the main bar, 13-24 the second bar above it.
ACTION_BUTTONS_PER_BAR = 12;
MAX_ACTION_BUTTONS = 24;

-- Console variable deciding whether the second action bar is shown.
ACTION_BAR_2_CVAR = "ShowActionBar2";

-- Gap (UI units) between the second bar and the experience bars below it, and between the second
-- bar and the player frame / cast bar it pushes up.
ACTION_BAR_2_GAP = (GameUITheme and GameUITheme.ActionBar2Gap) or 24;

-- Bottom offset of the player frame and cast bar while the second bar is hidden (matches the XML).
ACTION_BAR_2_HUD_DEFAULT_BOTTOM = -400;

-- Offset of the chat input above the menu bar while the second bar is hidden (matches the XML).
ACTION_BAR_2_CHAT_DEFAULT_BOTTOM = -24;

-- Tint used for the "active" glow shown on toggled ("Disabled While Active") spells such as Stealth.
ACTION_BUTTON_ACTIVE_GLOW = "FFFFD100";
ACTION_BUTTON_INACTIVE_GLOW = "00000000";

-- Socket tints of a bound slot, and of the translucent socket shown instead on empty second-bar slots.
ACTION_SOCKET_NORMAL_TINT = (GameUITheme and GameUITheme.ActionSocketNormalTint) or "FF998D7C";
ACTION_SOCKET_HOVERED_TINT = (GameUITheme and GameUITheme.ActionSocketHoveredTint) or "FFFFFFFF";
ACTION_SOCKET_PUSHED_TINT = (GameUITheme and GameUITheme.ActionSocketPushedTint) or "FF91806A";
ACTION_EMPTY_SOCKET_TINT = (GameUITheme and GameUITheme.ActionEmptySocketTint) or "4D998D7C";
ACTION_EMPTY_SOCKET_HOVER_TINT = (GameUITheme and GameUITheme.ActionEmptySocketHoverTint) or "A6FFFFFF";
ACTION_HIDDEN_TINT = "00000000";

-- Console variable deciding whether spell costs are printed on the action buttons.
ACTION_BAR_SHOW_COST_CVAR = "ActionBarShowCost";

-- Child indices of ActionBarButtonTemplate (see ActionBarButton.xml).
ACTION_BUTTON_CHILD_COOLDOWN = 0;
ACTION_BUTTON_CHILD_SHORTCUT = 1;
ACTION_BUTTON_CHILD_COOLDOWN_TEXT = 2;
ACTION_BUTTON_CHILD_COST = 3;
ACTION_BUTTON_CHILD_READY_FLASH = 4;

-- Cost text colours per power type (0 = mana, 1 = rage, 2 = energy). Slightly lighter than the
-- resource bars so the small digits stay readable on dark icons.
ACTION_COST_COLORS = {
    [0] = "FF5CAEFF",
    [1] = "FFFF5A46",
    [2] = "FFFFDC3C",
};
-- Cost colour while the player lacks the resource for the spell.
ACTION_COST_INSUFFICIENT_COLOR = "FF8C8C8C";

-- Cooldowns up to this long (seconds) count as the global cooldown: no countdown, no ready flash.
ACTION_COOLDOWN_GLOBAL_MAX = 2.0;
-- Below this many seconds the countdown turns warm and shows a tenth of a second.
ACTION_COOLDOWN_SOON = 3.0;
ACTION_COOLDOWN_TEXT_COLOR = "FFFFF6E0";
ACTION_COOLDOWN_SOON_COLOR = "FFFFC34D";

-- Spell id of the longer cooldown running on each slot, keyed by button id. Kept here and not on
-- the frames: Lua fields set on frame userdata do not survive between handler calls.
local actionCooldownLong = {};
-- Ready flashes currently playing, keyed by button id.
local actionReadyFlashes = {};

-- Fallback icon for emotes without an authored icon.
EMOTE_FALLBACK_ICON = "Interface/Icons/fg4_iconsFlat_dialogue.htex";

-- Number of pages the main bar can show. Page n shows the slots of bar n.
ACTION_BAR_PAGES = MAX_ACTION_BUTTONS / ACTION_BUTTONS_PER_BAR;

-- Page the main bar was switched to (ACTIONBARPAGE1 / ACTIONBARPAGE2), and whether the key that
-- shows page 2 for as long as it is held (ACTIONBARPAGE2HOLD) is down. Not saved: the main bar
-- starts on page 1 after every login.
local actionBarPage = 1;
local actionBarPageHeld = false;

-- Page the main bar shows right now.
function ActionBar_GetPage()
    return actionBarPageHeld and 2 or actionBarPage;
end

-- Zero-based action slot a button stands for. The twelve main bar buttons follow the main bar's
-- page; the second bar's buttons always are slots 13-24.
function ActionButton_GetSlot(button)
    if button.id <= ACTION_BUTTONS_PER_BAR then
        return (ActionBar_GetPage() - 1) * ACTION_BUTTONS_PER_BAR + button.id - 1;
    end
    return button.id - 1;
end

-- Text colours of the page number: quiet on the first page, lit while another page is shown.
ACTION_BAR_PAGE_COLOR = "FFB5A78B";
ACTION_BAR_PAGE_ACTIVE_COLOR = "FFFFD24F";

-- Shows the number of the page the main bar is on.
function ActionBar_UpdatePageIndicator()
    if ActionBarPageIndicator == nil then
        return;
    end

    local page = ActionBar_GetPage();
    ActionBarPageIndicator:SetText(tostring(page));
    ActionBarPageIndicator:SetProperty("TextColor", page == 1 and ACTION_BAR_PAGE_COLOR or ACTION_BAR_PAGE_ACTIVE_COLOR);
end

-- Redraws the main bar after its page changed.
local function ActionBar_OnPageChanged(previousPage)
    if ActionBar_GetPage() == previousPage then
        return;
    end

    -- The buttons now stand for other spells, whose cooldowns must not inherit the countdown and
    -- ready flash of the spells shown before.
    for i = 1, ACTION_BUTTONS_PER_BAR do
        actionCooldownLong[i] = nil;
    end

    GameTooltip:Hide();
    ActionBar_UpdateButtons();
    ActionBar_UpdatePageIndicator();
end

-- Switches the main bar to the given page until it is switched again.
function ActionBar_SetPage(page)
    if page < 1 or page > ACTION_BAR_PAGES then
        return;
    end

    local previousPage = ActionBar_GetPage();
    actionBarPage = page;
    ActionBar_OnPageChanged(previousPage);
end

-- Shows page 2 on the main bar while held, and the switched-to page again once released.
function ActionBar_HoldPage(held)
    local previousPage = ActionBar_GetPage();
    actionBarPageHeld = held;
    ActionBar_OnPageChanged(previousPage);
end

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

    if GameUITheme and GameUITheme.Wayfinder then
        Wayfinder_UpdateActionBarLayout(bar);
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

    -- The target frame, the pet bar and the pet frame above it are anchored to the player frame and
    -- follow it, so the pet bar never collides with this bar.
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
    if IsActionButtonSpell(ActionButton_GetSlot(self)) then
        local spell = GetActionButtonSpell(ActionButton_GetSlot(self));
        if (spell ~= nil) then
            GameTooltip:ClearAnchors();
            GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
            GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);
            GameTooltip_SetSpell(spell);
            GameTooltip:Show();
        end
    elseif IsActionButtonItem(ActionButton_GetSlot(self)) then
        local item = GetActionButtonItem(ActionButton_GetSlot(self));
        if (item ~= nil) then
            GameTooltip:ClearAnchors();
            GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
            GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);
            GameTooltip_SetItemTemplate(item);
            GameTooltip:Show();
        end
    elseif IsActionButtonEmote(ActionButton_GetSlot(self)) then
        local emote = GetActionButtonEmote(ActionButton_GetSlot(self));
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
    PickupActionButton(ActionButton_GetSlot(this));
end

function ActionBarButton_OnDrop(this, button, position)
    PickupActionButton(ActionButton_GetSlot(this));
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

    -- A key press always uses the slot. Only a Shift-click picks it up: Shift may be the key held
    -- to show page 2, and must then not turn every key press into a pickup.
    UseActionButton(ActionButton_GetSlot(button));
end

function ActionButton_OnClick(self, button)
    if (IsShiftKeyDown()) then
        PickupActionButton(ActionButton_GetSlot(self));
    else
        UseActionButton(ActionButton_GetSlot(self));
    end
end

function ActionBar_UpdateButtons(self)
    for i = 1, MAX_ACTION_BUTTONS do
        local button = _G["ActionButton"..i];
        if button ~= nil then
            local slot = ActionButton_GetSlot(button);

            button:SetOpacity(1.0);

            if IsActionButtonSpell(slot) then
                local spell = GetActionButtonSpell(slot);
                if (spell ~= nil) then
                    button:SetProperty("Icon", spell.icon);
                else
                    button:SetProperty("Icon", "");
                end

                button:SetText("");
            elseif IsActionButtonItem(slot) then
                local item = GetActionButtonItem(slot);

                if (item ~= nil) then
                    button:SetProperty("Icon", item.GetIcon(item));

                    local itemCount = GetItemCount(item.id);
                    button:SetText(tostring(itemCount));
                else
                    button:SetProperty("Icon", "");
                    button:SetText("");
                end
            elseif IsActionButtonEmote(slot) then
                local emote = GetActionButtonEmote(slot);

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
    local usable = IsActionButtonUsable(ActionButton_GetSlot(self));
    local occupied = IsActionButtonSpell(ActionButton_GetSlot(self)) or IsActionButtonItem(ActionButton_GetSlot(self)) or IsActionButtonEmote(ActionButton_GetSlot(self));
    if usable or not occupied then
        self:SetProperty("Color", "FFFFFFFF");
    else
        self:SetProperty("Color", "FF888888");
    end

    ActionButton_UpdateSocketStyle(self, occupied);

    -- Toggle the "active" glow for spells that stay active while their aura persists (e.g. Stealth).
    if IsActionButtonActive(ActionButton_GetSlot(self)) then
        self:SetProperty("ActiveGlowTint", ACTION_BUTTON_ACTIVE_GLOW);
    else
        self:SetProperty("ActiveGlowTint", ACTION_BUTTON_INACTIVE_GLOW);
    end

    -- Update cooldown display
    ActionButton_UpdateCooldown(self);

    ActionButton_UpdateCost(self);
end

-- Whether the interface option to print spell costs on the action buttons is enabled.
function ActionBar_IsCostShown()
    local value = GetCVar(ACTION_BAR_SHOW_COST_CVAR);
    return value ~= nil and value ~= "" and value ~= "0";
end

-- Prints the spell's (mod-adjusted) cost in its resource colour at the top left of the button.
function ActionButton_UpdateCost(self)
    local costFrame = self:GetChild(ACTION_BUTTON_CHILD_COST);
    if costFrame == nil then
        return;
    end

    local spell = nil;
    if ActionBar_IsCostShown() and IsActionButtonSpell(ActionButton_GetSlot(self)) then
        spell = GetActionButtonSpell(ActionButton_GetSlot(self));
    end

    local color = spell ~= nil and ACTION_COST_COLORS[spell.powertype] or nil;
    if spell == nil or spell.cost == 0 or color == nil then
        costFrame:Hide();
        return;
    end

    local cost = GetSpellEffectiveCost(spell.id);
    if cost == nil or cost <= 0 then
        costFrame:Hide();
        return;
    end

    local player = GetUnit("player");
    if player ~= nil and player:GetPower(spell.powertype) < cost then
        color = ACTION_COST_INSUFFICIENT_COLOR;
    end

    costFrame:SetText(string.format("%d", cost));
    costFrame:SetProperty("CostColor", color);
    costFrame:Show();
end

-- Plays the short glow shown when a longer cooldown finishes.
function ActionButton_PlayReadyFlash(self)
    local flash = self:GetChild(ACTION_BUTTON_CHILD_READY_FLASH);
    if flash == nil then
        return;
    end

    flash:SetOpacity(0.0);
    flash:Show();
    flash:PlayAnimation("Flash");
    actionReadyFlashes[self.id] = flash;
end

-- Hides ready flashes whose animation finished. Runs every frame, but only loops active flashes.
function ActionBar_UpdateReadyFlashes()
    for id, flash in pairs(actionReadyFlashes) do
        if not flash:IsAnimationPlaying("Flash") then
            flash:Hide();
            actionReadyFlashes[id] = nil;
        end
    end
end

-- Formats a remaining cooldown: minutes above a minute, tenths in the last seconds.
function ActionButton_FormatCooldown(remaining)
    if remaining >= 60 then
        return string.format("%dm", math.ceil(remaining / 60));
    end
    if remaining < ACTION_COOLDOWN_SOON then
        return string.format("%.1f", remaining);
    end
    return string.format("%d", math.ceil(remaining));
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
    local cooldownFrame = self:GetChild(ACTION_BUTTON_CHILD_COOLDOWN);
    if cooldownFrame == nil then
        return;
    end
    local cooldownText = self:GetChild(ACTION_BUTTON_CHILD_COOLDOWN_TEXT);

    -- Resolve the spell driving this button's cooldown. For spell buttons this is the spell
    -- itself; for item buttons it is the item's "On Use" spell (e.g. a potion's heal effect).
    local spell = nil;
    if IsActionButtonSpell(ActionButton_GetSlot(self)) then
        spell = GetActionButtonSpell(ActionButton_GetSlot(self));
    elseif IsActionButtonItem(ActionButton_GetSlot(self)) then
        spell = ActionButton_GetItemUseSpell(ActionButton_GetSlot(self));
    end

    if spell ~= nil and IsSpellOnCooldown(spell.id) then
        local progress = GetSpellCooldownProgress(spell.id);
        cooldownFrame:SetProgress(progress);
        cooldownFrame:Show();

        -- Total duration from remaining time and progress; the global cooldown stays quiet.
        local remaining = GetSpellCooldownRemaining(spell.id);
        local total = 0;
        if progress < 1.0 then
            total = remaining / (1.0 - progress);
        end

        if total > ACTION_COOLDOWN_GLOBAL_MAX then
            actionCooldownLong[self.id] = spell.id;
        end

        if cooldownText ~= nil then
            if actionCooldownLong[self.id] and remaining > 0 then
                cooldownText:SetText(ActionButton_FormatCooldown(remaining));
                if remaining < ACTION_COOLDOWN_SOON then
                    cooldownText:SetProperty("TextColor", ACTION_COOLDOWN_SOON_COLOR);
                else
                    cooldownText:SetProperty("TextColor", ACTION_COOLDOWN_TEXT_COLOR);
                end
                cooldownText:Show();
            else
                cooldownText:Hide();
            end
        end
    else
        cooldownFrame:SetProgress(1.0);
        cooldownFrame:Hide();
        if cooldownText ~= nil then
            cooldownText:Hide();
        end

        -- A longer cooldown just finished (not one that was cleared by swapping the slot's spell).
        local finishedSpellId = actionCooldownLong[self.id];
        if finishedSpellId ~= nil then
            actionCooldownLong[self.id] = nil;
            if spell ~= nil and spell.id == finishedSpellId then
                ActionButton_PlayReadyFlash(self);
            end
        end
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
    ActionBar_UpdateReadyFlashes();

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
            button:GetChild(ACTION_BUTTON_CHILD_SHORTCUT):SetText(text);
        end
    end
end
