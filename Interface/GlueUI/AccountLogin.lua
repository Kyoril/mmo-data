-- This script handles all the logic for the AccountLogin frame defined in the
-- AccountLogin.xml file.


-- Initiates a login attempt using the values from the name and password fields.
function AccountLogin_Login()
	local username = AccountNameField:GetText();
	local password = AccountPasswordField:GetText();

	LoginButton:Disable();

	GlueDialog_Show("CONNECTING");

	RunConsoleCommand("login " .. username .. " " .. password);
end

-- Called when the realm list was received — fade out, then show realm selection.
function AccountLogin_OnRealmList()
	GlueDialog_Hide();
	local anim = AccountLogin:GetAnimation("FadeOut")
	if anim and not anim:IsPlaying() then
		anim:SetOnFinish(function(a)
			a:SetOnFinish(nil);
			AccountLogin:Hide();
			RealmList_Show();
		end);

		AccountLogin:PlayAnimation("FadeOut");
	end
end

-- Called when the character list is ready — fade out, then show character select.
function AccountLogin_OnCharList()
	GlueDialog_Hide();
	CharList_Show();
	if pendingCharListError then
		GlueDialog_Show("ENTER_WORLD_FAILED", pendingCharListError);
		pendingCharListError = nil;
	end
end

function AccountLogin_AuthError(frame, errorCode)
	GlueDialog_Hide();
	LoginButton:Enable();
	GlueDialog_Show("AUTH_ERROR", AUTH_ERROR_STRING[errorCode]);
end

function AccountLogin_OnConnect()
	GlueDialog_Show("CONNECTING");
end

-- Called when the AccountLogin frame is loaded.
function AccountLogin_OnLoad()
	AccountLogin:RegisterEvent("AUTH_SUCCESS", function()
		GlueDialog_Show("RETRIEVE_REALM_LIST");
	end);
	AccountLogin:RegisterEvent("AUTH_FAILED", AccountLogin_AuthError);

	AccountLogin:RegisterEvent("REALM_AUTH_SUCCESS", function()
		GlueDialog_Show("RETRIEVE_CHAR_LIST");
	end);
	AccountLogin:RegisterEvent("REALM_AUTH_FAILED", function(frame, errorCode)
		GlueDialog_Hide();
		LoginButton:Enable();
		GlueDialog_Show("REALM_AUTH_ERROR", REALM_AUTH_ERROR_STRING[errorCode]);
	end);

	-- Shown while connecting to a realm (e.g. auto-connecting to the last used realm right after the
	-- realm list arrives). On cancel/confirm it returns to the realm list.
	AccountLogin:RegisterEvent("CONNECTING_TO_REALM", function()
		GlueDialog_Show("CONNECTING_TO_REALM");
	end);

	-- Realm dropped while still in the GlueUI: fade to black, land on login with error.
	AccountLogin:RegisterEvent("REALM_DISCONNECTED", function()
		-- If the realm just rejected our auth session (e.g. not allowed to connect), the
		-- REALM_AUTH_ERROR dialog is already showing and sends the player back to the realm list on
		-- confirm. The connection close that follows must not replace it.
		if GlueDialog.which == "REALM_AUTH_ERROR" then
			return;
		end

		GlueDialog_Hide();
		RealmListFrame:Hide();
		CharSelect:Hide();
		CharCreate:Hide();
		AccountLogin:Show();
		LoginButton:Enable();
		GlueDialog_Show("REALM_DISCONNECTED_ERROR");

		AccountLogin:PlayAnimation("FadeIn");
	end);

	AccountLogin:RegisterEvent("REALM_LIST", AccountLogin_OnRealmList);
	AccountLogin:RegisterEvent("CHAR_LIST", AccountLogin_OnCharList);
	AccountLogin:RegisterEvent("LOGIN_CONNECT", AccountLogin_OnConnect);

	if not realmConnector:IsConnected() then
		AccountNameField:CaptureInput();
	end

	AccountLogin:PlayAnimation("FadeIn");
end
