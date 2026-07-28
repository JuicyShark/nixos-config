-- ============================================================
-- MONITOR CONTROLLER
-- ============================================================
return function(ctx, opts)
	local hl = ctx.hl
	opts = opts or {}
	local desktop = opts.desktop or {}
	local streamDefaults = opts.stream or {}
	local policy = assert(ctx.monitorPolicy, "monitor-policy must load before monitor-states")
	local primary = assert(desktop.primary, "desktop.primary is required")
	local auxiliary = assert(desktop.auxiliary, "desktop.auxiliary is required")
	local streamOutput = assert(
		streamDefaults.monitor or (desktop.monitorWorkspace and desktop.monitorWorkspace.target),
		"stream monitor is required"
	)
	local debounceMs = tonumber(opts.debounceMs) or 180
	local retryMs = tonumber(opts.retryMs) or 250
	local recoveryMs = tonumber(opts.recoveryMs) or 5000
	local retryTicks = tonumber(opts.retryTicks) or 4
	local maxAttempts = tonumber(opts.maxAttempts) or 3
	_G.Juicy = _G.Juicy or {}
	local persistedIntent = _G.Juicy._monitorIntent or {}

	local intent = {
		profile = policy.normalizeProfile(persistedIntent.profile or desktop.defaultProfile or "solo"),
		stream = policy.normalizeStream(persistedIntent.stream or "off"),
	}
	local knownOutputs = {}
	local unavailable = {}
	local appliedSpecs = {}
	local enablePending = {}
	local disablePending = {}
	local applying = false
	local dirty = false
	local dirtyForce = false
	local settling = false
	local mutationCount = 0
	local transitionWorkspace = nil
	local reconcileTimer = nil
	local pendingReason = nil
	local pendingForce = false
	local reconcile
	local status = {
		phase = "initializing",
		reason = "load",
		error = nil,
		requestedProfile = intent.profile,
		effectiveProfile = nil,
		requestedStream = intent.stream.kind,
		effectiveStream = nil,
		degraded = nil,
	}

	local configuredOutputs = {
		{
			output = primary.output,
			selector = primary.selector or primary.output,
		},
		{
			output = auxiliary.output,
			selector = auxiliary.selector or auxiliary.output,
		},
		{
			output = streamOutput,
			selector = streamOutput,
		},
	}

	local function copy_table(values)
		local out = {}
		for key, value in pairs(values or {}) do
			if type(value) == "table" then
				out[key] = copy_table(value)
			else
				out[key] = value
			end
		end
		return out
	end

	local function persist_intent()
		_G.Juicy._monitorIntent = copy_table(intent)
	end

	local function monitor_snapshot(monitor)
		if not monitor then
			return nil
		end
		return {
			name = monitor.name,
			description = monitor.description,
			width = monitor.width,
			height = monitor.height,
			refresh = monitor.refresh_rate,
			scale = monitor.scale,
			x = monitor.x,
			y = monitor.y,
			focused = monitor.focused,
			vrr = monitor.vrr_active,
		}
	end

	local function get_monitor(selector)
		local ok, monitor = pcall(hl.get_monitor, selector)
		if ok then
			return monitor
		end
		return nil
	end

	local function observe()
		local outputs = {}
		for _, configured in ipairs(configuredOutputs) do
			local monitor = get_monitor(configured.selector)
			if monitor then
				outputs[configured.output] = monitor_snapshot(monitor)
				knownOutputs[configured.output] = true
				unavailable[configured.output] = nil
				enablePending[configured.output] = nil
			end
		end

		return {
			outputs = outputs,
			knownOutputs = copy_table(knownOutputs),
			unavailable = copy_table(unavailable),
		}
	end

	local function remember_focus()
		if transitionWorkspace then
			return
		end
		local workspace = hl.get_active_workspace()
		transitionWorkspace = workspace and workspace.name or nil
	end

	local function schedule(reason, delay, force)
		pendingReason = reason or pendingReason or "scheduled"
		pendingForce = pendingForce or force == true
		delay = tonumber(delay) or debounceMs

		if reconcileTimer then
			reconcileTimer:set_timeout(delay)
			reconcileTimer:set_enabled(true)
			return
		end

		reconcileTimer = hl.timer(function()
			local nextReason = pendingReason or "timer"
			local nextForce = pendingForce
			pendingReason = nil
			pendingForce = false
			settling = false
			reconcile(nextReason, nextForce)
		end, {
			timeout = delay,
			type = "oneshot",
		})
	end

	local function spec_signature(spec)
		return table.concat({
			tostring(spec.enabled),
			tostring(spec.mode),
			tostring(spec.position),
			tostring(spec.scale),
			tostring(spec.mirror),
		}, ":")
	end

	local function monitor_spec(spec, enabled)
		local rendered = {
			output = spec.output,
			disabled = not enabled,
		}
		if enabled then
			rendered.mode = spec.mode
			rendered.position = spec.position
			rendered.scale = spec.scale
			rendered.mirror = spec.mirror
		end
		return rendered
	end

	local function mutate(fn)
		fn()
		mutationCount = mutationCount + 1
		settling = true
	end

	local function next_attempt(bucket, output)
		local pending = bucket[output]
		if not pending then
			pending = {
				attempts = 0,
				ticks = retryTicks,
			}
			bucket[output] = pending
		end

		pending.ticks = pending.ticks + 1
		if pending.attempts >= maxAttempts then
			if pending.ticks >= retryTicks then
				return false, true
			end
			return false, false
		end

		if pending.ticks >= retryTicks then
			pending.attempts = pending.attempts + 1
			pending.ticks = 0
			return true, false
		end
		return false, false
	end

	local function ensure_enabled(spec, observed, force)
		if observed.outputs[spec.output] then
			enablePending[spec.output] = nil
			unavailable[spec.output] = nil
			local signature = spec_signature(spec)
			if force or appliedSpecs[spec.output] ~= signature then
				mutate(function()
					hl.monitor(monitor_spec(spec, true))
				end)
				appliedSpecs[spec.output] = signature
			end
			return "ready"
		end

		local attempt, failed = next_attempt(enablePending, spec.output)
		if failed then
			unavailable[spec.output] = true
			return "blocked"
		end
		if attempt then
			mutate(function()
				if spec.virtual then
					hl.exec_cmd(opts.hyprctl .. " output create headless " .. spec.output)
				else
					hl.monitor(monitor_spec(spec, true))
					appliedSpecs[spec.output] = spec_signature(spec)
				end
			end)
		end
		return "waiting"
	end

	local function ensure_disabled(spec, observed)
		if not observed.outputs[spec.output] then
			disablePending[spec.output] = nil
			appliedSpecs[spec.output] = nil
			return "ready"
		end

		local attempt, failed = next_attempt(disablePending, spec.output)
		if failed then
			return "blocked"
		end
		if attempt then
			mutate(function()
				if spec.virtual then
					hl.exec_cmd(opts.hyprctl .. " output remove " .. spec.output)
				else
					hl.monitor(monitor_spec(spec, false))
				end
			end)
		end
		return "waiting"
	end

	local function apply_workspace_plan(plan)
		if ctx.monitorWorkspace and ctx.monitorWorkspace.apply then
			ctx.monitorWorkspace.apply(plan.workspaces)
		end

		if transitionWorkspace then
			hl.dispatch(hl.dsp.focus({ workspace = transitionWorkspace }))
		end
	end

	local function apply_plan(plan, observed, force)
		local waiting = false
		for _, spec in ipairs(plan.outputs) do
			if spec.enabled then
				local result = ensure_enabled(spec, observed, force)
				if result == "blocked" then
					return "replan", spec.output
				elseif result == "waiting" then
					waiting = true
				end
			end
		end
		if waiting then
			return "waiting"
		end

		apply_workspace_plan(plan)

		for _, spec in ipairs(plan.outputs) do
			if not spec.enabled then
				local result = ensure_disabled(spec, observed)
				if result == "blocked" then
					return "failed", spec.output
				elseif result == "waiting" then
					waiting = true
				end
			end
		end
		if waiting then
			return "waiting"
		end
		return "stable"
	end

	local function project_state(plan)
		if not (ctx.state and ctx.state.setSource) then
			return
		end
		local effective = plan.status
		ctx.state.setSource("monitor-controller", "streaming", effective.effectiveStream == "local")
		ctx.state.setSource("monitor-controller", "remote-streaming", effective.effectiveStream == "remote")
		ctx.state.setSource(
			"monitor-controller",
			"double",
			effective.effectiveProfile == "extended" or effective.effectiveProfile == "mirror"
		)
	end

	local function update_status(plan, phase, reason, err)
		status.phase = phase
		status.reason = reason
		status.error = err
		status.requestedProfile = plan.status.requestedProfile
		status.effectiveProfile = plan.status.effectiveProfile
		status.requestedStream = plan.status.requestedStream
		status.effectiveStream = plan.status.effectiveStream
		status.degraded = plan.status.degraded
		status.outputs = observe().outputs
	end

	reconcile = function(reason, force)
		if applying then
			dirty = true
			dirtyForce = dirtyForce or force == true
			return
		end

		applying = true
		dirty = false
		mutationCount = 0
		local ok, err = pcall(function()
			if reason == "recover-degraded" then
				if intent.profile == "auto" or intent.profile == "extended" or intent.profile == "mirror" then
					unavailable[auxiliary.output] = nil
					enablePending[auxiliary.output] = nil
				end
				if intent.stream.kind ~= "off" then
					unavailable[streamOutput] = nil
					enablePending[streamOutput] = nil
				end
			end

			local observed = observe()
			local plan = policy.resolve(intent, observed)
			local result, output = apply_plan(plan, observed, force)

			if result == "replan" then
				observed = observe()
				plan = policy.resolve(intent, observed)
				result, output = apply_plan(plan, observed, true)
			end

			if result == "waiting" then
				update_status(plan, "waiting-output", reason)
				schedule("verify-output", retryMs)
			elseif result == "failed" then
				update_status(plan, "failed", reason, "unable to disable output: " .. tostring(output))
			else
				local phase = plan.status.degraded and "degraded" or "stable"
				update_status(plan, phase, reason)
				project_state(plan)
				transitionWorkspace = nil
				if plan.status.degraded then
					schedule("recover-degraded", recoveryMs)
				elseif mutationCount > 0 then
					schedule("verify-layout", retryMs)
				end
			end
		end)
		applying = false

		if not ok then
			status.phase = "failed"
			status.reason = reason
			status.error = tostring(err)
		end

		if dirty then
			local forceDirty = dirtyForce
			dirtyForce = false
			schedule("dirty-reconcile", debounceMs, forceDirty)
		end
	end

	local api = {}

	function api.setProfile(profile)
		profile = policy.normalizeProfile(profile)
		remember_focus()
		intent.profile = profile
		persist_intent()
		unavailable[auxiliary.output] = nil
		enablePending[auxiliary.output] = nil
		reconcile("profile:" .. profile, true)
	end

	function api.toggleProfile(profile)
		profile = policy.normalizeProfile(profile)
		if intent.profile == profile then
			api.setProfile("solo")
		else
			api.setProfile(profile)
		end
	end

	function api.setStream(stream)
		local normalized = policy.normalizeStream(stream)
		remember_focus()
		intent.stream = normalized
		persist_intent()
		unavailable[streamOutput] = nil
		enablePending[streamOutput] = nil
		disablePending[streamOutput] = nil
		reconcile("stream:" .. normalized.kind, true)
	end

	function api.toggleStream(kind)
		kind = policy.normalizeStream(kind).kind
		if intent.stream.kind == kind then
			api.setStream("off")
		else
			api.setStream(kind)
		end
	end

	function api.solo()
		remember_focus()
		intent.profile = "solo"
		intent.stream = policy.normalizeStream("off")
		persist_intent()
		unavailable[auxiliary.output] = nil
		unavailable[streamOutput] = nil
		enablePending = {}
		disablePending = {}
		reconcile("solo", true)
	end

	function api.reset()
		api.solo()
	end

	function api.reconcile()
		reconcile("manual-reconcile", true)
	end

	function api.intent()
		return copy_table(intent)
	end

	function api.status()
		local current = copy_table(status)
		current.intent = copy_table(intent)
		current.knownOutputs = copy_table(knownOutputs)
		current.unavailable = copy_table(unavailable)
		return current
	end

	ctx.monitors = api
	_G.Juicy.monitors = api

	local function topology_event(name)
		return function()
			schedule(name, debounceMs, not settling)
		end
	end

	hl.on("hyprland.start", topology_event("hyprland.start"))
	hl.on("config.reloaded", topology_event("config.reloaded"))
	hl.on("monitor.added", topology_event("monitor.added"))
	hl.on("monitor.removed", topology_event("monitor.removed"))
	hl.on("monitor.layout_changed", topology_event("monitor.layout_changed"))
end
