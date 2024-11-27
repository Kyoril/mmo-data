
COPPER_PER_SILVER = 100;
SILVER_PER_GOLD = 100;
COPPER_PER_GOLD = COPPER_PER_SILVER * SILVER_PER_GOLD;
MONEY_ICON_WIDTH = 0;
MONEY_BUTTON_SPACING = 16;
MONEY_ICON_WIDTH_SMALL = 0;
MONEY_BUTTON_SPACING_SMALL = 8;

MoneyTypeInfo = { };
MoneyTypeInfo["PLAYER"] = {
	UpdateFunc = function()
		return (UnitMoney("player"));
	end,

	PickupFunc = function(amount)
		
	end,

	DropFunc = function()
		
	end,

	collapse = 1,
	canPickup = 1,
	showSmallerCoins = "Backpack"
};

function MoneyFrame_OnLoad(this)
	this.staticMoney = 0;
	this.small = 0;
	this.canPickup = 0;
	this.hasPickup = 0;

	this:RegisterEvent("UNIT_MONEY", MoneyFrame_OnUnitMoney);
	MoneyFrame_SetType(this, "PLAYER");
end

function SmallMoneyFrame_OnLoad(this)
	this.staticMoney = 0;
	this.small = 1;
	this.canPickup = 0;
	this.hasPickup = 0;

	this:RegisterEvent("UNIT_MONEY", MoneyFrame_OnUnitMoney);
	MoneyFrame_SetType(this, "PLAYER");
end

function MoneyFrame_SetType(this, type)
	local info = MoneyTypeInfo[type];
	if ( not info ) then
		ELOG("Invalid money type: "..type);
		return;
	end

	this.moneyType = type;
	this.canPickup = info.canPickup;

	local frameName = this:GetName();
	if ( this.canPickup == 0 ) then
		getglobal(frameName.."_GoldButton"):Disable();
		getglobal(frameName.."_SilverButton"):Disable();
		getglobal(frameName.."_CopperButton"):Disable();
	else
		getglobal(frameName.."_GoldButton"):Enable();
		getglobal(frameName.."_SilverButton"):Enable();
		getglobal(frameName.."_CopperButton"):Enable();
	end

	MoneyFrame_UpdateMoney();
end

function MoneyFrame_UpdateMoney()
	local info = MoneyTypeInfo[this.moneyType];
	if ( info ) then
		local money = info.UpdateFunc();
		RefreshMoneyFrame(this:GetName(), money, this.small, info.collapse, info.showSmallerCoins);
		if ( this.hasPickup == 1 ) then
			UpdateCoinPickupFrame(money);
		end
	end
end

function RefreshMoneyFrame(frameName, money, small, collapse, showSmallerCoins)
	local gold = math.floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = math.floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = math.fmod(money, COPPER_PER_SILVER);

	local goldButton = _G[frameName.."_GoldButton"];
	local silverButton = _G[frameName.."_SilverButton"];
	local copperButton = _G[frameName.."_CopperButton"];

	local iconWidth = MONEY_ICON_WIDTH;
	local spacing = MONEY_BUTTON_SPACING;
	if ( small ) then
		iconWidth = MONEY_ICON_WIDTH_SMALL;
		spacing = MONEY_BUTTON_SPACING_SMALL;
	end

	goldButton:SetText(tostring(gold));
	goldButton:SetWidth(goldButton:GetTextWidth() + iconWidth);
	goldButton:Show();
	silverButton:SetText(tostring(silver));
	silverButton:SetWidth(silverButton:GetTextWidth() + iconWidth);
	silverButton:Show();
	copperButton:SetText(tostring(copper));
	copperButton:SetWidth(copperButton:GetTextWidth() + iconWidth);
	copperButton:Show();

	local frame = _G[frameName];
	frame.staticMoney = money;

	if ( collapse ) then
		return;
	end

	local width = 13;
	local showLowerDenominations;
	if ( gold > 0 ) then
		width = width + goldButton:GetWidth();
		if ( showSmallerCoins ) then
			showLowerDenominations = true;
		end
	else
		goldButton:Hide();
	end

	if ( silver > 0 or showLowerDenominations ) then
		width = width + silverButton:GetWidth();

		goldButton:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.LEFT, silverButton, -spacing);
		if ( goldButton:IsVisible() ) then
			width = width - spacing;
		end
		if ( showSmallerCoins ) then
			showLowerDenominations = true;
		end
	else
		silverButton:Hide();
		goldButton:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, silverButton, 0);
	end

	-- Used if we're not showing lower denominations
	if ( copper > 0 or showLowerDenominations or showSmallerCoins) then
		width = width + copperButton:GetWidth();
		silverButton:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.LEFT, copperButton, -spacing);
		if ( silverButton:IsVisible() ) then
			width = width - spacing;
		end
	else
		copperButton:Hide();
		silverButton:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, copperButton, 0);
	end

	frame:SetWidth(width);
end

function SetMoneyFrameColor(frameName, r, g, b)
	local goldButton = getglobal(frameName.."GoldButton");
	local silverButton = getglobal(frameName.."SilverButton");
	local copperButton = getglobal(frameName.."CopperButton");

	goldButton:SetTextColor(r, g, b);
	silverButton:SetTextColor(r, g, b);
	copperButton:SetTextColor(r, g, b);
end
