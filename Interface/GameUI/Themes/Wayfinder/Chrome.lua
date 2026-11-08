-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
function Wayfinder_AddTitleRule(parent, title, inset, offset)
	local rule = WayfinderTitleRule:Clone();
	parent:AddChild(rule);
	rule:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, parent, inset);
	rule:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, parent, -inset);
	rule:SetAnchor(AnchorPoint.V_CENTER, AnchorPoint.BOTTOM, title, offset);
	return rule;
end
