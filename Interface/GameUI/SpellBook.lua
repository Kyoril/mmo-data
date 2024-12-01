
SpellBookPage = 1

SPELLS_PER_PAGE = 12

function SpellBook_UpdatePage()
    if (SpellBookPage > 1) then
        SpellBookPrevPageButton:Enable();
    else
        SpellBookPrevPageButton:Disable();
    end

    SpellBookPageLabel:SetText(string.format(Localize("SPELL_BOOK_PAGE_FORMAT"), SpellBookPage));

    -- Refresh all spell buttons
    for i = 1, SPELLS_PER_PAGE do
        local button = _G["SpellBookButton" .. string.format("%02d", i)];
        button.userData = i - 1;
        SpellButton_Update(button);
    end

end

function SpellButton_OnClick(self)
    
    local id = tonumber(self.userData);
    if (id == nil) then
        self:Disable();
        return;
    end

    local spellIndex = id + (SpellBookPage - 1) * SPELLS_PER_PAGE;
    CastSpell(spellIndex)

end

function SpellButton_OnEnter(self)
    
    local id = tonumber(self.userData);
    if (id == nil) then
        self:Disable();
        return;
    end

    local spellIndex = id + (SpellBookPage - 1) * SPELLS_PER_PAGE;
    local spell = GetSpell(spellIndex);

    GameTooltip:ClearAnchors()
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, self, 0)
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, self, 16)

    GameTooltip_SetSpell(spell)
    
    GameTooltip:Show()
end

function SpellButton_OnLeave(self)
    GameTooltip:Hide()
end

function SpellButton_Update(button)
    
    local id = tonumber(button.userData);
    if (id == nil) then
        button:Disable();
        return;
    end

    local spellIndex = id + (SpellBookPage - 1) * SPELLS_PER_PAGE;
    local spell = GetSpell(spellIndex);

    if (spell == nil) then
        button:GetChild(0):SetText("");
        button:GetChild(1):SetText("");
        button:SetProperty("icon", "");
        button:Disable();
        return;
    end

    button:GetChild(0):SetText(spell.name);
    button:GetChild(1):SetText("Rank 1");
    button:SetProperty("icon", spell.icon);
    button:Enable();

end

function SpellBook_Toggle()
    if (SpellBook:IsVisible()) then
        HideUIPanel(SpellBook);
    else
        SpellBook_UpdatePage();
        ShowUIPanel(SpellBook);
    end
end

function SpellBook_NextPage()
    SpellBookPage = SpellBookPage + 1;
    SpellBook_UpdatePage();
end

function SpellBook_PrevPage()
    SpellBookPage = SpellBookPage - 1;
    SpellBook_UpdatePage();
end

function SpellBook_SpellsChanged(self)
    SpellBook_UpdatePage();
end

function SpellBook_OnLoad(self)
    SpellBookPage = 1;

    self:RegisterEvent("SPELL_LEARNED", ActionBar_UpdateButtons);

    for i = 1, SPELLS_PER_PAGE do
        local button = _G["SpellBookButton" .. string.format("%02d", i)];
        button.userData = i - 1;
        button:SetClickedHandler(SpellButton_OnClick);
        button:SetOnEnterHandler(SpellButton_OnEnter);
        button:SetOnLeaveHandler(SpellButton_OnLeave);
    end

	SpellBookTitleBar:GetChild(0):SetClickedHandler(SpellBook_Toggle);
    
    SpellBook_UpdatePage();
end

