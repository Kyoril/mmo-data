
COPPER_PER_SILVER = 100;
SILVER_PER_GOLD = 100;
COPPER_PER_GOLD = COPPER_PER_SILVER * SILVER_PER_GOLD;

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
		getglobal(frameName.."GoldButton"):Disable();
		getglobal(frameName.."SilverButton"):Disable();
		getglobal(frameName.."CopperButton"):Disable();
	else
		getglobal(frameName.."GoldButton"):Enable();
		getglobal(frameName.."SilverButton"):Enable();
		getglobal(frameName.."CopperButton"):Enable();
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
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = mod(money, COPPER_PER_SILVER);

	local goldButton = getglobal(frameName.."GoldButton");
	local silverButton = getglobal(frameName.."SilverButton");
	local copperButton = getglobal(frameName.."CopperButton");

	local iconWidth = MONEY_ICON_WIDTH;
	local spacing = MONEY_BUTTON_SPACING;
	if ( small > 0 ) then
		iconWidth = MONEY_ICON_WIDTH_SMALL;
		spacing = MONEY_BUTTON_SPACING_SMALL;
	end

	goldButton:SetText(gold);
	goldButton:SetWidth(goldButton:GetTextWidth() + iconWidth);
	goldButton:Show();
	silverButton:SetText(silver);
	silverButton:SetWidth(silverButton:GetTextWidth() + iconWidth);
	silverButton:Show();
	copperButton:SetText(copper);
	copperButton:SetWidth(copperButton:GetTextWidth() + iconWidth);
	copperButton:Show();

	local frame = getglobal(frameName);
	frame.staticMoney = money;

	if ( collapse == 0 ) then
		return;
	end

	local width = 13;
	local showLowerDenominations;
	if ( gold > 0 ) then
		width = width + goldButton:GetWidth();
		if ( showSmallerCoins ) then
			showLowerDenominations = 1;
		end
	else
		goldButton:Hide();
	end

	if ( silver > 0 or showLowerDenominations ) then
		width = width + silverButton:GetWidth();
		goldButton:SetPoint("RIGHT", frameName.."SilverButton", "LEFT", spacing, 0);
		if ( goldButton:IsVisible() ) then
			width = width - spacing;
		end
		if ( showSmallerCoins ) then
			showLowerDenominations = 1;
		end
	else
		silverButton:Hide();
		goldButton:SetPoint("RIGHT", frameName.."SilverButton",	"RIGHT", 0, 0);
	end

	-- Used if we're not showing lower denominations
	if ( copper > 0 or showLowerDenominations or showSmallerCoins == "Backpack") then
		width = width + copperButton:GetWidth();
		silverButton:SetPoint("RIGHT", frameName.."CopperButton", "LEFT", spacing, 0);
		if ( silverButton:IsVisible() ) then
			width = width - spacing;
		end
	else
		copperButton:Hide();
		silverButton:SetPoint("RIGHT", frameName.."CopperButton", "RIGHT", 0, 0);
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
