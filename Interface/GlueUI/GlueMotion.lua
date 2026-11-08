-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Eased tweens for the Glue screens. XML animations interpolate linearly between keyframes; these
-- drive any frame value (opacity, anchor offsets, sizes) through an easing curve from Lua instead.
-- GlueParent's OnUpdate calls GlueMotion_Update every frame.
--
-- Tweens are keyed: starting a tween under a key that is already running replaces it, so a hover
-- that ends halfway through its enter tween simply turns around from where it is.

GlueMotion = {};

local tweens = {};
local order = {};

local function Clamp01(t)
	if t < 0 then return 0; end
	if t > 1 then return 1; end
	return t;
end

GlueEase = {
	Linear = function(t) return t; end,
	OutCubic = function(t) t = 1 - t; return 1 - t * t * t; end,
	InCubic = function(t) return t * t * t; end,
	InOutCubic = function(t)
		if t < 0.5 then return 4 * t * t * t; end
		t = -2 * t + 2;
		return 1 - t * t * t / 2;
	end,
	OutQuint = function(t) t = 1 - t; return 1 - t * t * t * t * t; end,
	OutBack = function(t)
		local c1 = 1.4;
		local c3 = c1 + 1;
		t = t - 1;
		return 1 + c3 * t * t * t + c1 * t * t;
	end,
};

-- Starts (or replaces) a tween.
-- opts: from, to, duration (s), delay (s), ease (GlueEase.*), apply(value), done().
function GlueMotion.Tween(key, opts)
	if tweens[key] == nil then
		table.insert(order, key);
	end
	tweens[key] = {
		from = opts.from or 0,
		to = opts.to or 1,
		duration = math.max(opts.duration or 0.3, 0.0001),
		delay = opts.delay or 0,
		ease = opts.ease or GlueEase.OutCubic,
		apply = opts.apply,
		done = opts.done,
		time = 0,
		value = opts.from or 0,
	};
	-- Apply the start value at once, so a delayed entrance does not flash its final state.
	if opts.apply then
		opts.apply(opts.from or 0);
	end
end

-- Current value of a running tween, or nil.
function GlueMotion.Value(key)
	local tween = tweens[key];
	return tween and tween.value or nil;
end

function GlueMotion.IsRunning(key)
	return tweens[key] ~= nil;
end

-- Stops a tween where it is, without calling its done handler.
function GlueMotion.Cancel(key)
	tweens[key] = nil;
end

-- Jumps a tween to its end value and calls its done handler.
function GlueMotion.Finish(key)
	local tween = tweens[key];
	if not tween then
		return;
	end
	tweens[key] = nil;
	if tween.apply then tween.apply(tween.to); end
	if tween.done then tween.done(); end
end

function GlueMotion_Update(elapsed)
	if #order == 0 then
		return;
	end

	local finished = nil;
	local keep = {};
	for _, key in ipairs(order) do
		local tween = tweens[key];
		if tween then
			tween.time = tween.time + elapsed;
			local t = Clamp01((tween.time - tween.delay) / tween.duration);
			if tween.time >= tween.delay then
				tween.value = tween.from + (tween.to - tween.from) * tween.ease(t);
				if tween.apply then tween.apply(tween.value); end
			end
			if t >= 1 then
				tweens[key] = nil;
				if tween.done then
					finished = finished or {};
					table.insert(finished, tween.done);
				end
			else
				table.insert(keep, key);
			end
		end
	end
	order = keep;

	-- Done handlers run after the pass: they may start new tweens.
	if finished then
		for _, done in ipairs(finished) do
			done();
		end
	end
end

local function Key(frame, channel)
	return frame:GetName() .. ":" .. channel;
end

-- Fades a frame's own opacity. Showing it first when fading in; hiding it after fading out to 0.
function GlueMotion.Fade(frame, to, duration, delay, done, ease)
	local from = frame:IsVisible() and frame:GetOpacity(false) or 0;
	if to > 0 then
		frame:Show();
	end
	GlueMotion.Tween(Key(frame, "opacity"), {
		from = from, to = to, duration = duration or 0.25, delay = delay or 0, ease = ease or GlueEase.OutCubic,
		apply = function(v) frame:SetOpacity(v); end,
		done = function()
			if to <= 0 then frame:Hide(); end
			if done then done(); end
		end,
	});
end

-- Moves one anchor of a frame from one offset to another (UI units).
function GlueMotion.Offset(frame, channel, point, relativePoint, relativeTo, from, to, duration, delay, ease, done)
	GlueMotion.Tween(Key(frame, channel), {
		from = from, to = to, duration = duration or 0.35, delay = delay or 0, ease = ease or GlueEase.OutCubic,
		apply = function(v) frame:SetAnchor(point, relativePoint, relativeTo, v); end,
		done = done,
	});
end

-- Entrance: fades a frame in while sliding one anchor from offset + distance to offset.
function GlueMotion.Enter(frame, point, relativePoint, relativeTo, offset, distance, delay, duration)
	frame:SetOpacity(0);
	GlueMotion.Fade(frame, 1, (duration or 0.45) * 0.8, delay, nil, GlueEase.OutCubic);
	GlueMotion.Offset(frame, "enter", point, relativePoint, relativeTo, offset + distance, offset, duration or 0.45, delay, GlueEase.OutQuint);
end

-- Interpolates two ARGB colours ("FFRRGGBB") and returns the mixed hex string.
function GlueMotion.MixColor(a, b, t)
	local result = "";
	for i = 1, 7, 2 do
		local x = tonumber(string.sub(a, i, i + 1), 16);
		local y = tonumber(string.sub(b, i, i + 1), 16);
		result = result .. string.format("%02X", math.floor(x + (y - x) * t + 0.5));
	end
	return result;
end

-- Tweens a colour property (e.g. "TextColor", "RimColor") between two ARGB strings.
function GlueMotion.Color(frame, property, from, to, duration, delay)
	GlueMotion.Tween(Key(frame, "color:" .. property), {
		from = 0, to = 1, duration = duration or 0.2, delay = delay or 0, ease = GlueEase.OutCubic,
		apply = function(t) frame:SetProperty(property, GlueMotion.MixColor(from, to, t)); end,
	});
end
