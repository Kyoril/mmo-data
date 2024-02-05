
function TargetFrame_OnLoad()
    TargetFrame_Update();

    TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED", TargetFrame_Update);
end

function TargetFrame_Update()
    if (UnitExists("target")) then
        TargetName:SetText("Level " .. UnitLevel("target") .. " " .. UnitName("target"));

        -- Update progress bars
        health = UnitHealth("target");
        maxHealth = UnitHealthMax("target");
        if (maxHealth == 0) then
            health = 0;
            maxHealth = 1;
        end

        healthPct = health / maxHealth;
        TargetHealthBar:SetProgress(healthPct);
        TargetHealthBar:SetText(math.floor(healthPct * 100) .. "%");

        mana = UnitMana("target");
        maxMana = UnitManaMax("target");
        if (maxMana == 0) then
            mana = 0;
            maxMana = 1;
        end

        manaPct = mana / maxMana;
        TargetManaBar:SetProgress(manaPct);
        TargetManaBar:SetText(math.floor(manaPct * 100) .. "%");

        TargetFrame:Show();
    else
        TargetFrame:Hide();
    end
end

