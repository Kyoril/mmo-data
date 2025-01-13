
function FadingFrame_SetFadeInTime(this, time)
	this.fadeInTime = time;
end

function FadingFrame_SetHoldTime(this, time)
	this.holdTime = time;
end

function FadingFrame_SetFadeOutTime(this, time)
	this.fadeOutTime = time;
end

function FadingFrame_OnLoad(this)
	this.fadeInTime = 0;
	this.holdTime = 0;
	this.fadeOutTime = 0;
	this:Hide();
end

function FadingFrame_Show(this)
	this.startTime = GetTime();
	this:Show();
end

function FadingFrame_OnUpdate(this)
	local elapsed = GetTime() - this.startTime;

	local fadeInTime = this.fadeInTime;
	if ( elapsed < fadeInTime ) then
		local alpha = (elapsed / fadeInTime);
		this:SetOpacity(alpha);
		return;
	end

	local holdTime = this.holdTime;
	if ( elapsed < (fadeInTime + holdTime) ) then
		this:SetOpacity(1.0);
		return;
	end

	local fadeOutTime = this.fadeOutTime;
	if ( elapsed < (fadeInTime + holdTime + fadeOutTime) ) then
		local alpha = 1.0 - ((elapsed - holdTime - fadeInTime) / fadeOutTime);
		this:SetOpacity(alpha);
		return;
	end

	this:Hide();
end