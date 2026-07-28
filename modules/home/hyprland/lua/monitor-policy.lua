-- ============================================================
-- MONITOR POLICY
-- ============================================================
return function(ctx, opts)
	opts = opts or {}
	local desktop = opts.desktop or {}
	local streamDefaults = opts.stream or {}
	local primary = assert(desktop.primary, "desktop.primary is required")
	local auxiliary = assert(desktop.auxiliary, "desktop.auxiliary is required")
	local streamOutput = assert(
		streamDefaults.monitor or (desktop.monitorWorkspace and desktop.monitorWorkspace.target),
		"stream monitor is required"
	)
	local groups = desktop.workspaceGroups or {}
	local externalWorkspaces = groups.external
		or (desktop.monitorWorkspace and desktop.monitorWorkspace.workspaces)
		or {}
	local auxiliaryWorkspaces = groups.auxiliary or externalWorkspaces
	local streamWorkspaces = groups.stream or externalWorkspaces
	local validProfiles = {
		auto = true,
		solo = true,
		extended = true,
		mirror = true,
	}
	local validStreamKinds = {
		off = true,
		["local"] = true,
		remote = true,
	}

	local function copy_list(values)
		local out = {}
		for _, value in ipairs(values or {}) do
			out[#out + 1] = value
		end
		return out
	end

	local function normalize_profile(profile)
		profile = tostring(profile or desktop.defaultProfile or "solo")
		if not validProfiles[profile] then
			error("unknown monitor profile: " .. profile)
		end
		return profile
	end

	local function normalize_stream(stream)
		if type(stream) == "string" then
			stream = { kind = stream }
		else
			stream = stream or {}
		end

		local kind = tostring(stream.kind or "off")
		if not validStreamKinds[kind] then
			error("unknown monitor stream kind: " .. kind)
		end

		return {
			kind = kind,
			width = tonumber(stream.width) or streamDefaults.width or 2560,
			height = tonumber(stream.height) or streamDefaults.height or 1440,
			refresh = tonumber(stream.refresh) or streamDefaults.refresh or 120,
			scale = tonumber(stream.scale) or streamDefaults.scale or 1.67,
		}
	end

	local function physical_spec(role, enabled)
		return {
			output = assert(role.output, "monitor output is required"),
			selector = role.selector or role.output,
			enabled = enabled,
			mode = role.mode or "preferred",
			position = role.position,
			scale = role.scale or 1,
		}
	end

	local function stream_spec(stream, enabled, remote)
		return {
			output = streamOutput,
			selector = streamOutput,
			enabled = enabled,
			virtual = true,
			mode = string.format("%dx%d@%d", stream.width, stream.height, stream.refresh),
			position = remote and "0x0" or (streamDefaults.position or "0x1440"),
			scale = stream.scale,
		}
	end

	local function resolve(intent, observed)
		intent = intent or {}
		observed = observed or {}
		local unavailable = observed.unavailable or {}
		local knownOutputs = observed.knownOutputs or {}
		local requestedProfile = normalize_profile(intent.profile)
		local stream = normalize_stream(intent.stream)
		local effectiveProfile = requestedProfile
		local effectiveStream = stream.kind
		local degraded = nil

		if requestedProfile == "auto" then
			if knownOutputs[auxiliary.output] and not unavailable[auxiliary.output] then
				effectiveProfile = "extended"
			else
				effectiveProfile = "solo"
			end
		elseif (requestedProfile == "extended" or requestedProfile == "mirror") and unavailable[auxiliary.output] then
			effectiveProfile = "solo"
			degraded = "auxiliary output unavailable: " .. auxiliary.output
		end

		if stream.kind ~= "off" and unavailable[streamOutput] then
			effectiveStream = "off"
			degraded = "stream output unavailable: " .. streamOutput
		end

		local remote = effectiveStream == "remote"
		local localStream = effectiveStream == "local"
		local extended = effectiveProfile == "extended"
		local mirrored = effectiveProfile == "mirror"
		local outputs = {
			physical_spec(primary, not remote),
			physical_spec(auxiliary, not remote and (extended or mirrored)),
			stream_spec(stream, remote or localStream, remote),
		}

		if mirrored then
			outputs[2].mirror = primary.selector or primary.output
		end

		local assignments = {}
		if remote then
			assignments[1] = {
				workspaces = copy_list(externalWorkspaces),
				monitor = streamOutput,
			}
		elseif localStream and extended then
			assignments[1] = {
				workspaces = copy_list(auxiliaryWorkspaces),
				monitor = auxiliary.selector or auxiliary.output,
			}
			assignments[2] = {
				workspaces = copy_list(streamWorkspaces),
				monitor = streamOutput,
			}
		elseif localStream then
			assignments[1] = {
				workspaces = copy_list(externalWorkspaces),
				monitor = streamOutput,
			}
		elseif extended then
			assignments[1] = {
				workspaces = copy_list(externalWorkspaces),
				monitor = auxiliary.selector or auxiliary.output,
			}
		else
			assignments[1] = {
				workspaces = copy_list(externalWorkspaces),
				monitor = primary.selector or primary.output,
			}
		end

		return {
			outputs = outputs,
			workspaces = assignments,
			status = {
				requestedProfile = requestedProfile,
				effectiveProfile = effectiveProfile,
				requestedStream = stream.kind,
				effectiveStream = effectiveStream,
				degraded = degraded,
			},
		}
	end

	ctx.monitorPolicy = {
		normalizeProfile = normalize_profile,
		normalizeStream = normalize_stream,
		resolve = resolve,
	}
end
