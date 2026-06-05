
-- Variables
selectedRealm = nil			-- Selected realm name


function RealmListItem_Clicked(item)
	selectedRealm = item.userData
	RealmListButton01:Enable()
end

function RealmList_Show()
	RealmListFrame:Show()
	RealmListButton01:Disable()

	-- Clear realm list entries
	RealmList:RemoveAllChildren()

	-- Reset selected realm
	selectedRealm = nil

	-- Remember the last cloned realm list item as we need it as anchor
	-- reference frame to align the list items beneath each other
	local lastRealmListItem = nil

	-- Load realm list data for iteration
	local realms = loginConnector:GetRealms()
	for realm in realms do
		-- Clone item
		local realmListItem = RealmListItem:Clone()
		RealmList:AddChild(realmListItem)

		-- Assign realm data
		realmListItem:SetText(realm.name)
		realmListItem.userData = realm

		-- Setup anchor points
		if lastRealmListItem ~= nil then
			realmListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, lastRealmListItem, 0.0)
		else
			realmListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0.0)
		end
		realmListItem:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0.0)
		realmListItem:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0.0)

		-- Register click handler
		realmListItem:SetClickedHandler(RealmListItem_Clicked)

		-- Remember realm list item
		lastRealmListItem = realmListItem
	end

	RealmListFrame:PlayAnimation("FadeIn");
end

function RealmList_Hide()
	RealmListFrame:Hide();
end

function RealmList_Accept()
	RealmList_Hide();
	GlueDialog_Show("CONNECTING_TO_REALM")
	realmConnector:ConnectToRealm(selectedRealm)
end

function RealmList_Cancel()
	local anim = RealmListFrame:GetAnimation("FadeOut");
	if anim and not anim:IsPlaying() then
		anim:SetOnFinish(function(a)
			a:SetOnFinish(nil);

			RealmList_Hide();
			AccountLogin:Show();
			AccountLogin:PlayAnimation("FadeIn");
			LoginButton:Enable();
		end);

		RealmListFrame:PlayAnimation("FadeOut");
	end
end
