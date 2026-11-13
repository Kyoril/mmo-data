-- Pet action bar: the fixed pet commands, then the active abilities of the persistent pet.
-- This is client state of its own (PetInfo), not character action slots.

-- Button layout. PetActionButton1..5 are the commands, PetActionButton6..11 the abilities.
PET_ACTION_ATTACK = 1;
PET_ACTION_FOLLOW = 2;
PET_ACTION_STAY = 3;
PET_ACTION_STRATEGY = 4;
PET_ACTION_DISMISS = 5;
PET_ACTION_COMMAND_BUTTONS = 5;
PET_ACTION_ABILITY_BUTTONS = 6;
PET_ACTION_BUTTONS = PET_ACTION_COMMAND_BUTTONS + PET_ACTION_ABILITY_BUTTONS;

-- pet_strategy and pet_level_mode values (src/shared/game/pet_defines.h).
PET_STRATEGY_ASSIST = 0;
PET_STRATEGY_PASSIVE = 1;
PET_LEVEL_MODE_OWN = 0;

-- Tint of the glow marking the strategy toggle while the pet assists.
PET_ACTION_ACTIVE_GLOW = "FFFFD100";
PET_ACTION_INACTIVE_GLOW = "00000000";

-- Command button icons.
local petCommandIcons = {
    [PET_ACTION_ATTACK] = "Interface/Icons/fg4_icons_daggers_result.htex",
    [PET_ACTION_FOLLOW] = "Interface/Icons/fg4_icons_boots_result.htex",
    [PET_ACTION_STAY] = "Interface/Icons/fg4_icons_shield_result.htex",
    [PET_ACTION_STRATEGY] = "Interface/Icons/fg4_icons_shieldSword_result.htex",
    [PET_ACTION_DISMISS] = "Interface/Icons/fg4_iconsGold_close_result.htex",
};

-- Pet spell index (GetPetSpell) shown by each ability slot, 1-based by slot. Kept in a file
-- local instead of on the buttons, whose Lua fields do not survive between handler calls.
local petAbilitySpellIndex = {};

local function PetActionBar_GetButton(id)
    return _G["PetActionButton" .. id];
end

-- The pet spell index of an ability button, or nil for a command button or an empty slot.
local function PetActionButton_GetSpellIndex(self)
    local slot = self.id - PET_ACTION_COMMAND_BUTTONS;
    if slot < 1 then
        return nil;
    end

    return petAbilitySpellIndex[slot];
end

local function PetActionButton_GetCommandText(id)
    if id == PET_ACTION_ATTACK then
        return Localize("PET_ATTACK");
    elseif id == PET_ACTION_FOLLOW then
        return Localize("PET_FOLLOW");
    elseif id == PET_ACTION_STAY then
        return Localize("PET_STAY");
    elseif id == PET_ACTION_STRATEGY then
        if GetPetStrategy() == PET_STRATEGY_PASSIVE then
            return Localize("PET_PASSIVE");
        end
        return Localize("PET_ASSIST");
    elseif id == PET_ACTION_DISMISS then
        return Localize("PET_DISMISS");
    end

    return "";
end

function PetActionButton_UpdateCooldown(self)
    local cooldownFrame = self:GetChild(0);
    -- Only a Cooldown frame has SetProgress; bail out if the overlay failed to load.
    if cooldownFrame == nil or cooldownFrame.SetProgress == nil then
        return;
    end

    local index = PetActionButton_GetSpellIndex(self);
    if index ~= nil then
        local remaining = GetPetSpellCooldown(index);
        local duration = GetPetSpellCooldownDuration(index);
        if remaining > 0 and duration > 0 then
            cooldownFrame:SetProgress(1.0 - remaining / duration);
            cooldownFrame:Show();
            return;
        end
    end

    cooldownFrame:SetProgress(1.0);
    cooldownFrame:Hide();
end

-- Marks the strategy toggle as checked while the pet assists.
local function PetActionBar_UpdateStrategy()
    local button = PetActionBar_GetButton(PET_ACTION_STRATEGY);
    local assisting = GetPetStrategy() == PET_STRATEGY_ASSIST;
    button:SetChecked(assisting);
    if assisting then
        button:SetProperty("ActiveGlowTint", PET_ACTION_ACTIVE_GLOW);
    else
        button:SetProperty("ActiveGlowTint", PET_ACTION_INACTIVE_GLOW);
    end
end

-- Fills the ability slots with the active (non-passive) spells of the persistent pet.
local function PetActionBar_UpdateAbilities()
    petAbilitySpellIndex = {};

    if HasPersistentPet() then
        for index = 0, GetNumPetSpells() - 1 do
            local spell = GetPetSpell(index);
            if spell ~= nil and not IsPassiveSpell(spell) and #petAbilitySpellIndex < PET_ACTION_ABILITY_BUTTONS then
                table.insert(petAbilitySpellIndex, index);
            end
        end
    end

    for slot = 1, PET_ACTION_ABILITY_BUTTONS do
        local button = PetActionBar_GetButton(PET_ACTION_COMMAND_BUTTONS + slot);
        local index = petAbilitySpellIndex[slot];
        local spell = index ~= nil and GetPetSpell(index) or nil;
        if spell ~= nil then
            button:SetProperty("Icon", spell.icon);
            button:Show();
        else
            button:SetProperty("Icon", "");
            button:Hide();
        end

        PetActionButton_UpdateCooldown(button);
    end
end

-- The bar is passed in by its event handlers and OnLoad, where the frame is not yet reachable
-- through its global name.
function PetActionBar_Update(self)
    local bar = self or PetActionBar;

    -- Shown while a persistent pet is summoned or temporary pets are out (HasPetUI covers both);
    -- temporary pets get the commands only.
    if not HasPetUI() then
        bar:Hide();
        PetActionBar_UpdateHudLayout();
        return;
    end

    for id = 1, PET_ACTION_COMMAND_BUTTONS do
        PetActionBar_GetButton(id):Show();
    end

    PetActionBar_UpdateStrategy();
    PetActionBar_UpdateAbilities();
    bar:Show();
    PetActionBar_UpdateHudLayout();
end

-- The Wayfinder cast bar sits above the pet bar while that is shown. Skipped while the UI still
-- loads (the cast bar comes later in the TOC); the theme lays everything out once at the end.
function PetActionBar_UpdateHudLayout()
    if GameUITheme and GameUITheme.Wayfinder and PlayerCastBar ~= nil and ActionBar2 ~= nil then
        Wayfinder_UpdateActionBarLayout(ActionBar2);
    end
end

function PetActionButton_OnClick(self, button)
    local id = self.id;
    if id == PET_ACTION_ATTACK then
        PetAttack();
    elseif id == PET_ACTION_FOLLOW then
        PetFollow();
    elseif id == PET_ACTION_STAY then
        PetStay();
    elseif id == PET_ACTION_STRATEGY then
        -- A click on a checkable button flips its checked state. Show the requested strategy until
        -- the server confirms it with PET_CHANGED.
        if GetPetStrategy() == PET_STRATEGY_ASSIST then
            PetSetStrategy(PET_STRATEGY_PASSIVE);
            self:SetChecked(false);
        else
            PetSetStrategy(PET_STRATEGY_ASSIST);
            self:SetChecked(true);
        end
    elseif id == PET_ACTION_DISMISS then
        PetDismiss();
    else
        local index = PetActionButton_GetSpellIndex(self);
        if index ~= nil then
            PetCastSpell(index);
        end
    end
end

function PetActionButton_OnEnter(self)
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    if self.id <= PET_ACTION_COMMAND_BUTTONS then
        GameTooltip_Clear();
        GameTooltip_AddLine(PetActionButton_GetCommandText(self.id), TOOLTIP_LINE_LEFT, "FFFFD100");
        GameTooltip:Show();
        return;
    end

    local index = PetActionButton_GetSpellIndex(self);
    local spell = index ~= nil and GetPetSpell(index) or nil;
    if spell ~= nil then
        GameTooltip_SetSpell(spell);
        GameTooltip:Show();
    end
end

function PetActionButton_OnLeave(self)
    GameTooltip:Hide();
end

-- Pet errors (PET_RESULT carries a localization key) go to the UI error frame.
function PetActionBar_OnPetResult(self, key)
    if key == nil or key == "" then
        return;
    end

    UIErrorFrame_AddMessage(Localize(key), "FFFF1900");
end

function PetActionBar_OnLoad(self)
    for id = 1, PET_ACTION_BUTTONS do
        local button = PetActionBar_GetButton(id);
        button:SetClickedHandler(PetActionButton_OnClick);
        button:SetOnEnterHandler(PetActionButton_OnEnter);
        button:SetOnLeaveHandler(PetActionButton_OnLeave);
        if id <= PET_ACTION_COMMAND_BUTTONS then
            button:SetProperty("Icon", petCommandIcons[id]);
        end
    end

    self:RegisterEvent("PLAYER_ENTER_WORLD", PetActionBar_Update);
    self:RegisterEvent("PET_CHANGED", PetActionBar_Update);
    self:RegisterEvent("PET_SPELLS_CHANGED", PetActionBar_Update);
    self:RegisterEvent("PET_RESULT", PetActionBar_OnPetResult);

    PetActionBar_Update(self);
end
