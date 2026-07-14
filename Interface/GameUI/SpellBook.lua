
SpellBookPage = 1
SpellBookTab = 1

SPELLS_PER_PAGE = 12
SPELLBOOK_TAB_GENERAL = 1
SPELLBOOK_TAB_ABILITIES = 2
SPELLBOOK_TAB_SKILLS = 3
SPELLBOOK_MAX_TABS = 3

local SpellBookVisibleSpells = {}

local function SpellBook_GetCategory(spell)
    if (spell == nil) then
        return SPELLBOOK_TAB_GENERAL;
    end

    if (spell:IsSkill()) then
        return SPELLBOOK_TAB_SKILLS;
    end

    if (spell:IsAbility()) then
        return SPELLBOOK_TAB_ABILITIES;
    end

    return SPELLBOOK_TAB_GENERAL;
end

local function SpellBook_GetTabText(tabId)
    if (tabId == SPELLBOOK_TAB_ABILITIES) then
        return Localize("SPELLBOOK_TAB_ABILITIES");
    end

    if (tabId == SPELLBOOK_TAB_SKILLS) then
        return Localize("SPELLBOOK_TAB_SKILLS");
    end

    return Localize("SPELLBOOK_TAB_GENERAL");
end

local function SpellBook_RebuildVisibleSpells()
    SpellBookVisibleSpells = {};

    local spellIndex = 0;
    while true do
        local spell = GetSpell(spellIndex);
        if (spell == nil) then
            break;
        end

        if (SpellBook_GetCategory(spell) == SpellBookTab) then
            table.insert(SpellBookVisibleSpells, spell);
        end

        spellIndex = spellIndex + 1;
    end
end

local function SpellBook_GetSpellAtPageIndex(index)
    return SpellBookVisibleSpells[index + 1];
end

function SpellBook_UpdateTabs()
    for i = 1, SPELLBOOK_MAX_TABS do
        local tabButton = _G["SpellBookTab" .. i];
        tabButton:SetText(SpellBook_GetTabText(i));

        if (i == SpellBookTab) then
            tabButton:SetChecked(true);
        else
            tabButton:SetChecked(false);
        end
    end
end

function SpellBook_UpdatePage()
    SpellBook_RebuildVisibleSpells();

    local maxPage = math.max(1, math.ceil(#SpellBookVisibleSpells / SPELLS_PER_PAGE));
    if (SpellBookPage > maxPage) then
        SpellBookPage = maxPage;
    end

    SpellBookPrevPageButton:Show();
    SpellBookNextPageButton:Show();
    SpellBookPageLabel:Show();

    if (SpellBookPage > 1) then
        SpellBookPrevPageButton:Enable();
    else
        SpellBookPrevPageButton:Disable();
    end

    if (SpellBookPage < maxPage) then
        SpellBookNextPageButton:Enable();
    else
        SpellBookNextPageButton:Disable();
    end

    SpellBookPageLabel:SetText(string.format(Localize("SPELL_BOOK_PAGE_FORMAT"), SpellBookPage));

    if (#SpellBookVisibleSpells == 0) then
        SpellBookEmptyLabel:Show();
    else
        SpellBookEmptyLabel:Hide();
    end

    SpellBook_UpdateTabs();

    -- Refresh all spell buttons
    for i = 1, SPELLS_PER_PAGE do
        local button = _G["SpellBookButton" .. string.format("%02d", i)];
        button.userData = i - 1;
        SpellButton_Update(button);
    end

end

function SpellButton_OnClick(self, button)
    
    local id = tonumber(self.userData);
    if (id == nil) then
        self:Disable();
        return;
    end

    local spellIndex = id + (SpellBookPage - 1) * SPELLS_PER_PAGE;
    local spell = SpellBook_GetSpellAtPageIndex(spellIndex);
    if (spell == nil) then
        return;
    end

    if button == "LEFT" then
        PickupSpell(spell.id);
    else
        CastSpellById(spell.id)
    end
end

function SpellButton_OnEnter(self)
    
    local id = tonumber(self.userData);
    if (id == nil) then
        self:Disable();
        return;
    end

    local spellIndex = id + (SpellBookPage - 1) * SPELLS_PER_PAGE;
    local spell = SpellBook_GetSpellAtPageIndex(spellIndex);
    if (spell == nil) then
        return;
    end

    GameTooltip:ClearAnchors()
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, self, 0)
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, self, 16)

    GameTooltip_SetSpell(spell)
    
    GameTooltip:Show()
end

function SpellButton_OnLeave(self)
    GameTooltip:Hide()
end

function SpellButton_OnDrag(self)
    local id = tonumber(self.userData);
    if (id == nil) then
        return;
    end

    local spellIndex = id + (SpellBookPage - 1) * SPELLS_PER_PAGE;
    local spell = SpellBook_GetSpellAtPageIndex(spellIndex);
    if (spell == nil) then
        return;
    end

    -- Pick up a copy of the spell for drag-and-drop onto the action bar.
    -- This does not remove the spell from the spellbook.
    PickupSpell(spell.id);
end

function SpellButton_Update(button)
    
    local id = tonumber(button.userData);
    if (id == nil) then
        button:Disable();
        return;
    end

    local spellIndex = id + (SpellBookPage - 1) * SPELLS_PER_PAGE;
    local spell = SpellBook_GetSpellAtPageIndex(spellIndex);

    if (spell == nil) then
        button:GetChild(0):SetText("");
        button:GetChild(1):SetText("");
        button:SetProperty("icon", "");
        button:Hide();
        return;
    end

    button:Show();
    button:GetChild(0):SetText(spell.name);

    if spell.rank > 0 then
        button:GetChild(1):SetText(string.format(Localize("SPELL_RANK_FORMAT"), spell.rank));
    else
        button:GetChild(1):SetText("");
    end
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

function SpellBook_SelectTab(tabId)
    if (tabId ~= SpellBookTab) then
        SpellBookTab = tabId;
        SpellBookPage = 1;
        SpellBook_UpdatePage();
    else
        SpellBook_UpdateTabs();
    end
end

function SpellBookTab_OnClick(self)
    SpellBook_SelectTab(self.id);
end

function SpellBook_OnShow(self)
    PlaySound("Sound/Interface/Papers_01.wav");
end

function SpellBook_OnLoad(self)
    SpellBookPage = 1;
    SpellBookTab = SPELLBOOK_TAB_GENERAL;

    self:RegisterEvent("SPELL_LEARNED", ActionBar_UpdateButtons);

    -- Rebuild the spellbook whenever the active spellbook is replaced (spawn, class switch, etc.),
    -- so switching class updates the visible spells immediately instead of on the next open.
    self:RegisterEvent("PLAYER_SPELLS_CHANGED", SpellBook_SpellsChanged);

    for i = 1, SPELLS_PER_PAGE do
        local button = _G["SpellBookButton" .. string.format("%02d", i)];
        button.userData = i - 1;
        button:SetClickedHandler(SpellButton_OnClick);
        button:SetOnEnterHandler(SpellButton_OnEnter);
        button:SetOnLeaveHandler(SpellButton_OnLeave);
        button:SetOnDragHandler(SpellButton_OnDrag);
    end

    for i = 1, SPELLBOOK_MAX_TABS do
        local tabButton = _G["SpellBookTab" .. i];
        tabButton:SetClickedHandler(SpellBookTab_OnClick);
    end

	SpellBookTitleBar:GetChild(0):SetClickedHandler(SpellBook_Toggle);
    
    SpellBook_UpdatePage();
    
    AddMenuBarButton("Interface/Icons/fg4_icons_firesword_result.htex", SpellBook_Toggle, "MENUBAR_TOOLTIP_SPELLBOOK", "TOGGLESPELLBOOK");
end

