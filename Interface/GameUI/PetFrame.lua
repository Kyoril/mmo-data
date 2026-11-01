-- Pet frame: portrait, name, level, health and power of the summoned persistent pet, plus an
-- experience bar for pets that level on their own (PET_LEVEL_MODE_OWN, see PetActionBar.lua).

-- Power bar tints per power type (the same as the player frame's).
local petPowerColors = {
    [0] = "FF328FEA", -- Mana
    [1] = "FFE94B38", -- Rage
    [2] = "FFF0C632", -- Energy
};

local function PetFrame_SetBar(bar, value, maxValue)
    if maxValue == nil or maxValue <= 0 then
        bar:SetProgress(0);
        bar:SetText("");
        return;
    end

    bar:SetProgress(value / maxValue);
    bar:SetText(value .. " / " .. maxValue);
end

function PetFrame_UpdateExperience()
    if GetPetLevelMode() ~= PET_LEVEL_MODE_OWN then
        PetExperienceBar:Hide();
        return;
    end

    local xp, nextLevelXp = GetPetXp();
    PetFrame_SetBar(PetExperienceBar, xp, nextLevelXp);
    PetExperienceBar:Show();
end

-- The frame is passed in by its event handlers and OnLoad, where it is not yet reachable through
-- its global name.
function PetFrame_Update(self)
    local frame = self or PetFrame;

    local pet = GetUnit("pet");
    if not HasPersistentPet() or pet == nil then
        frame:Hide();
        return;
    end

    local name = pet:GetName();
    if name == nil or name == "" then
        name = Localize("PET");
    end
    PetName:SetText(name);
    PetPortraitLevel:SetText(tostring(pet:GetLevel()));

    PetFrame_SetBar(PetHealthBar, pet:GetHealth(), pet:GetMaxHealth());

    local powerType = pet:GetPowerType();
    PetManaBar:SetProperty("ProgressColor", petPowerColors[powerType] or petPowerColors[0]);
    PetFrame_SetBar(PetManaBar, pet:GetPower(powerType), pet:GetMaxPower(powerType));

    PetFrame_UpdateExperience();
    frame:Show();
end

-- A new or returning pet also needs its portrait model.
function PetFrame_OnPetChanged(self)
    PetPortraitModel:SetUnit("pet");
    PetFrame_Update(self);
end

function PetFrame_OnUnitUpdate(self, unit)
    if unit == "pet" then
        PetFrame_Update(self);
    end
end

function PetFrame_OnXpUpdate(self)
    PetFrame_UpdateExperience();
end

function PetFrame_OnClick(self, button, x, y)
    if button == "LEFT" then
        TargetUnit("pet");
    elseif button == "RIGHT" then
        -- The PET_FRAME menu (Rename / Dismiss) is registered in ContextMenu.lua.
        ContextMenu_Show("PET_FRAME", x, y, nil);
    end
end

function PetFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTER_WORLD", PetFrame_OnPetChanged);
    self:RegisterEvent("PET_CHANGED", PetFrame_OnPetChanged);
    self:RegisterEvent("PET_XP_UPDATE", PetFrame_OnXpUpdate);
    self:RegisterEvent("UNIT_HEALTH_UPDATED", PetFrame_OnUnitUpdate);
    self:RegisterEvent("UNIT_POWER_UPDATED", PetFrame_OnUnitUpdate);
    self:RegisterEvent("UNIT_LEVEL_UPDATED", PetFrame_OnUnitUpdate);
    self:RegisterEvent("UNIT_NAME_UPDATE", PetFrame_OnUnitUpdate);

    PetFrame_Update(self);
end
