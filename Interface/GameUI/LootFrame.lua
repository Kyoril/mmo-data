LOOTFRAME_NUMBUTTONS = 4;

LOOT_SLOT_ALLOW_LOOT = 0;
LOOT_SLOT_ROLL_ONGOING = 1;
LOOT_SLOT_MASTER = 2;
LOOT_SLOT_LOCKED = 3;

-- Caption of an item the player cannot take right now, by slot type ("%s" = item name).
LOOT_SLOT_STATUS_KEYS = {
    [LOOT_SLOT_ROLL_ONGOING] = "LOOT_SLOT_ROLLING",
    [LOOT_SLOT_MASTER] = "LOOT_SLOT_MASTER",
    [LOOT_SLOT_LOCKED] = "LOOT_SLOT_LOCKED",
};

local function IsCvarOn(val)
    return val ~= nil and val ~= "0" and val ~= "" and val ~= "false";
end

-- Determines whether this loot should be auto-looted. Fast Loot is a cvar (off by default);
-- holding Shift while opening the loot inverts the behaviour for that single loot.
local function ShouldFastLoot()
    local enabled = IsCvarOn(GetCVar("FastLoot"));
    if IsShiftKeyDown() then
        return not enabled;
    end
    return enabled;
end

-- Fast loot does not empty the window in one go: the window stays up and takes one slot after the
-- other, so the player sees what was looted. Times are in seconds.
local AUTOLOOT_START_DELAY = 0.3;		-- window shown untouched before the first slot is taken
local AUTOLOOT_TOTAL_DURATION = 1.0;	-- the time the slots are spread over...
local AUTOLOOT_MIN_INTERVAL = 0.15;		-- ...but never faster than this per slot
local AUTOLOOT_MAX_INTERVAL = 0.35;		-- ...and never slower than this per slot
local AUTOLOOT_CLOSE_DELAY = 0.4;		-- empty window lingers this long before it closes
local AUTOLOOT_REQUEST_TIMEOUT = 1.0;	-- a request unanswered this long failed (e.g. bags full)

-- Fast loot state. It must not live on 'self': every handler call gets a new wrapper of the frame,
-- and fields set on one wrapper are invisible through the next.
local autoLoot = { active = false };

-- Returns the UI slot of the next slot fast loot should take, ignoring the first 'skip' lootable
-- slots (requests for those were never answered, so they stay for the player). Slots that cannot
-- be looted (locked, being rolled on, master-looter controlled) are never taken.
local function FindNextAutoLootSlot(skip)
    local numLootItems = GetNumLootItems();
    for slot = 1, numLootItems, 1 do
        if GetLootSlotType(slot) == LOOT_SLOT_ALLOW_LOOT then
            if skip == 0 then
                return slot;
            end
            skip = skip - 1;
        end
    end
    return nil;
end

-- Starts fast looting the open loot. The slots are taken one by one from LootFrame_AutoLootTick.
function LootFrame_AutoLootAll(self)
    local numLootable = 0;
    local numLootItems = GetNumLootItems();
    for slot = 1, numLootItems, 1 do
        if GetLootSlotType(slot) == LOOT_SLOT_ALLOW_LOOT then
            numLootable = numLootable + 1;
        end
    end

    local interval = AUTOLOOT_MAX_INTERVAL;
    if numLootable > 1 then
        interval = math.max(AUTOLOOT_MIN_INTERVAL, math.min(AUTOLOOT_MAX_INTERVAL, AUTOLOOT_TOTAL_DURATION / (numLootable - 1)));
    end

    autoLoot.active = true;
    autoLoot.closing = false;
    autoLoot.interval = interval;
    autoLoot.timer = AUTOLOOT_START_DELAY;
    autoLoot.pending = false;
    autoLoot.pendingTime = 0;
    autoLoot.skip = 0;
end

-- Advances fast looting. Only one loot request is in flight at a time: UI slots shift as slots are
-- cleared, so the next slot is only picked once the previous request was answered. Returns true
-- if the loot was closed.
function LootFrame_AutoLootTick(self, elapsed)
    if not autoLoot.active then
        return false;
    end

    if autoLoot.closing then
        autoLoot.timer = autoLoot.timer - elapsed;
        if autoLoot.timer <= 0 then
            autoLoot.active = false;
            CloseLoot();
            return true;
        end
        return false;
    end

    -- The interval runs while a request is in flight, so server latency overlaps it.
    autoLoot.timer = autoLoot.timer - elapsed;

    if autoLoot.pending then
        autoLoot.pendingTime = autoLoot.pendingTime + elapsed;
        if autoLoot.pendingTime < AUTOLOOT_REQUEST_TIMEOUT then
            return false;
        end

        -- No answer: the slot could not be looted (an error was shown). Leave it to the player.
        autoLoot.pending = false;
        autoLoot.skip = autoLoot.skip + 1;
    end

    if autoLoot.timer > 0 then
        return false;
    end

    local slot = FindNextAutoLootSlot(autoLoot.skip);
    if slot then
        LootSlot(slot, false);
        autoLoot.pending = true;
        autoLoot.pendingTime = 0;
        autoLoot.timer = autoLoot.interval;
        return false;
    end

    -- Nothing left to take. An empty window lingers briefly, then closes; if items remain (locked by
    -- party loot rules, or bags full), the window stays open so the player can handle them.
    if GetNumLootItems() == 0 then
        autoLoot.closing = true;
        autoLoot.timer = AUTOLOOT_CLOSE_DELAY;
    else
        autoLoot.active = false;
    end
    return false;
end

function LootFrame_OnLootOpened(self)
    self.page = 1;
    LootFrame.page = 1; -- Keep global reference for button handlers
    autoLoot.active = false;

    ShowUIPanel(self);

    if not self:IsVisible() then
        CloseLoot();
        return;
    end

    if ShouldFastLoot() then
        LootFrame_AutoLootAll(self);
    end
end

function LootFrame_OnLootSlotCleared(self, absoluteSlot)
    -- Ensure numLootItems is set, if not get it from the API
    if not self.numLootItems then
        self.numLootItems = GetNumLootItems();
    end
    
    -- Ensure page is set, default to 1
    if not self.page then
        self.page = 1;
        LootFrame.page = 1; -- Keep global reference for button handlers
    end
    
    -- Update the numLootItems to reflect current state
    self.numLootItems = GetNumLootItems();

	-- Update the empty label visibility
	local emptyLabel = LootEmptyLabel;
	if emptyLabel then
		if self.numLootItems == 0 then
			emptyLabel:SetText(Localize("LOOT_EMPTY"));
			emptyLabel:Show();
		else
			emptyLabel:Hide();
		end
	end

	-- Fast loot's request was answered. With nothing left to take, let the next tick start closing
	-- right away instead of waiting out the interval.
	if autoLoot.active and autoLoot.pending then
		autoLoot.pending = false;
		if not FindNextAutoLootSlot(autoLoot.skip) then
			autoLoot.timer = 0;
		end
	end

    -- Trigger a UI update to refresh the display
    LootFrame_OnUpdate(self, 0);
end

function LootFrame_OnLootClosed(self)
    autoLoot.active = false;
    HideUIPanel(LootFrame);
end

function LootButton_OnEnter(this)
	local slot = (LOOTFRAME_NUMBUTTONS * (LootFrame.page - 1)) + this.id;

	if LootSlotIsItem(slot) then
		local entry = GetLootSlotItem(slot);
		if not entry then
			return;
		end

		GameTooltip:ClearAnchors();
		GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, this, 16);
		GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, this, -16);
		GameTooltip_SetItemTemplate(entry);
		GameTooltip:Show();
	else
		return;
	end
end

function LootButton_OnLeave(this)
	GameTooltip:Hide();
end

function LootFrame_OnLoad(self)
	for index = 1, LOOTFRAME_NUMBUTTONS, 1 do
		local button = getglobal("LootButton"..index);
		if button then
			button:SetClickedHandler(LootButton_OnClick);
			button:SetOnEnterHandler(LootButton_OnEnter);
			button:SetOnLeaveHandler(LootButton_OnLeave);
		end
	end

	-- Subscribe for title bar close handler (HACKY! Order of items is important which sucks)
	LootFrame:GetChild(0):GetChild(0):SetClickedHandler(LootFrame_OnLootClosed);

    self:RegisterEvent("LOOT_OPENED", LootFrame_OnLootOpened);
    self:RegisterEvent("LOOT_SLOT_CLEARED", LootFrame_OnLootSlotCleared);
    self:RegisterEvent("LOOT_CLOSED", LootFrame_OnLootClosed);
end

function LootFrame_OnShow(self)
	self.numLootItems = GetNumLootItems();
	LootFrame_OnUpdate(self, 0);

	-- Show "No loot" label when loot window is empty
	local emptyLabel = LootEmptyLabel;
	if emptyLabel then
		if self.numLootItems == 0 then
			emptyLabel:SetText(Localize("LOOT_EMPTY"));
			emptyLabel:Show();
		else
			emptyLabel:Hide();
		end
	end

	if ( self.numLootItems == 0 ) then
		-- TODO: Play sound of empty loot window opening
	else
		-- TODO: Play sound of loot window opening
	end
end

function LootFrame_OnHide()
	CloseLoot();
end

function LootButton_OnClick(button)
	local numLootToShow = LOOTFRAME_NUMBUTTONS;
	local numLootItems = LootFrame.numLootItems or GetNumLootItems();
	if numLootItems > LOOTFRAME_NUMBUTTONS then
		numLootToShow = numLootToShow - 1;
	end

	local slot = (numLootToShow * ((LootFrame.page or 1) - 1)) + button.id;
	local slotType = GetLootSlotType(slot);

	-- Master loot items are handed out, never looted: the loot master picks who gets it.
	if slotType == LOOT_SLOT_MASTER and IsLootMaster() then
		local pos = GetCursorPosition();
		ContextMenu_Show("MASTER_LOOT", pos.x, pos.y, slot);
		return;
	end

	if slotType == LOOT_SLOT_ROLL_ONGOING or slotType == LOOT_SLOT_LOCKED or slotType == LOOT_SLOT_MASTER then
		return;
	end

	LootSlot(slot, false);
end

function LootFrame_OnUpdate(self, elapsed)
	if LootFrame_AutoLootTick(self, elapsed) then
		return;
	end

	local numLootItems = self.numLootItems;
	
	-- Safety check in case numLootItems is nil
	if not numLootItems then
		numLootItems = GetNumLootItems();
		self.numLootItems = numLootItems;
	end
	
	-- Safety check in case page is nil
	if not self.page then
		self.page = 1;
		LootFrame.page = 1; -- Keep global reference for button handlers
	end
	
    local numLootToShow = LOOTFRAME_NUMBUTTONS;
	
	if ( numLootItems > LOOTFRAME_NUMBUTTONS ) then
		numLootToShow = numLootToShow - 1;
	end

    for index = 1, LOOTFRAME_NUMBUTTONS, 1 do
		local button = getglobal("LootButton"..index);
		local text = getglobal("LootText"..index);
		local border = getglobal("LootButton"..index.."Border");
		local slot = (numLootToShow * (self.page - 1)) + index;

		if ( slot <= numLootItems ) then	
			if ( (LootSlotIsItem(slot) or LootSlotIsCoin(slot)) and index <= numLootToShow ) then
				local texture;
				local item;
				local quantity = 1;
				local slotType = GetLootSlotType(slot);
				texture, item, quantity = GetLootSlotInfo(slot);
				button:SetProperty("Icon", texture);
				-- The loot master's master loot items stay bright: clicking them hands them out.
				local canAssign = (slotType == LOOT_SLOT_MASTER and IsLootMaster());
				local isLocked = not canAssign and (slotType == LOOT_SLOT_ROLL_ONGOING or slotType == LOOT_SLOT_LOCKED or slotType == LOOT_SLOT_MASTER);

				if LootSlotIsItem(slot) then
					local entry = GetLootSlotItem(slot);
					if canAssign then
						text:SetText(string.format(Localize("LOOT_SLOT_ASSIGN"), item));
						text:SetProperty("Color", ItemQualityColors[entry.quality]);
					elseif isLocked then
						text:SetText(string.format(Localize(LOOT_SLOT_STATUS_KEYS[slotType] or "LOOT_SLOT_LOCKED"), item));
						text:SetProperty("Color", "FF808080");
					else
						text:SetText(item);
						text:SetProperty("Color", ItemQualityColors[entry.quality]);
					end
				else
					text:SetText(item);
					text:SetProperty("Color", "FFFFFFFF");
				end

				if ( quantity > 1 ) then
					button:SetText(tostring(quantity));
				else
					button:SetText("");
				end
				if isLocked then
					button:SetOpacity(0.5);
					border:SetOpacity(0.6);
				else
					button:SetOpacity(1.0);
					border:SetOpacity(1.0);
				end
				button:Show(); -- Ensure button is visible
				border:Show();
			else
				button:Hide(); -- Hide button when no valid item
				border:Hide();
			end
		else
			button:Hide(); -- Hide button when slot is beyond available items
			border:Hide();
		end
	end
end