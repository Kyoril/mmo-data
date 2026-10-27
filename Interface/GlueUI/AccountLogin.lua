-- This script handles all the logic for the AccountLogin frame defined in the
-- AccountLogin.xml file.


-- Reads a boolean console variable, which is missing entirely until it is first set.
local function IsCvarOn(val)
	return val == "1" or val == "true";
end

-- Called when the "remember account name" checkbox was clicked. The client clears the stored
-- account name by itself whenever the option is switched off, so only the option is written
-- here. The password is never stored.
function AccountLogin_OnRememberAccountNameToggled()
	SetCVar("rememberAccountName", RememberAccountNameCheck:IsChecked() and "1" or "0");
	RunConsoleCommand("saveconfig");
end

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
	-- The list is re-sent every few seconds while the realm list is open: update it in place so
	-- the selection, scroll position and screen stay put.
	if RealmListFrame:IsVisible() then
		RealmList_Update();
		return;
	end

	-- A refresh that lands while a realm connection is in progress must not replace its dialog.
	if GlueDialog:IsVisible() and GlueDialog.which == "CONNECTING_TO_REALM" then
		return;
	end

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
	AccountLogin:RegisterEvent("REALM_DISCONNECTED", function(frame, kickReason)
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
		AccountNameField:CaptureInput();

		-- The realm sends a reason when it terminated the session on purpose (account signed in
		-- elsewhere, banned). Anything else is an ordinary drop and gets the generic message.
		local reasonText = kickReason and KICK_REASON_STRING[kickReason];
		if reasonText then
			GlueDialog_Show("SESSION_KICKED_ERROR", reasonText);
		else
			GlueDialog_Show("REALM_DISCONNECTED_ERROR");
		end

		AccountLogin:PlayAnimation("FadeIn");
	end);

	-- The login server terminated this session, most commonly because the account was signed in
	-- somewhere else while we sat on the realm list. The disconnect follows immediately.
	AccountLogin:RegisterEvent("ACCOUNT_KICKED", function(frame, kickReason)
		-- A reason this client build does not know still means the session is gone, so say
		-- something generic rather than leaving the player on a screen that no longer works.
		local reasonText = (kickReason and KICK_REASON_STRING[kickReason]) or "REALM_DISCONNECTED";

		GlueDialog_Hide();
		RealmListFrame:Hide();
		CharSelect:Hide();
		CharCreate:Hide();
		AccountLogin:Show();
		LoginButton:Enable();
		AccountNameField:CaptureInput();
		GlueDialog_Show("SESSION_KICKED_ERROR", reasonText);

		AccountLogin:PlayAnimation("FadeIn");
	end);

	AccountLogin:RegisterEvent("REALM_LIST", AccountLogin_OnRealmList);
	AccountLogin:RegisterEvent("CHAR_LIST", AccountLogin_OnCharList);
	AccountLogin:RegisterEvent("ENTER_WORLD_REQUESTED", function()
		CharSelect_OnEnterWorldRequested();
	end);
	AccountLogin:RegisterEvent("LOGIN_CONNECT", AccountLogin_OnConnect);

	-- The account name of the last login is only kept while the option is enabled, so an empty
	-- value means there is nothing to restore.
	RememberAccountNameCheck:SetChecked(IsCvarOn(GetCVar("rememberAccountName")));

	local rememberedAccountName = GetCVar("accountName") or "";
	if rememberedAccountName ~= "" then
		AccountNameField:SetText(rememberedAccountName);
	end

	if not realmConnector:IsConnected() then
		-- With the account name already filled in, the password is what the player still has to
		-- type, so start there instead.
		if rememberedAccountName ~= "" then
			AccountPasswordField:CaptureInput();
		else
			AccountNameField:CaptureInput();
		end
	end

	AccountLogin:PlayAnimation("FadeIn");
end
