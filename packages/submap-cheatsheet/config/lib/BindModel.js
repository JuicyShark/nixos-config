.pragma library
.import "HyprHelpers.js" as HyprHelpers

// Pure bind normalization and grouping. Keeping this module free of QML object
// state makes the native Hyprland metadata contract independently testable.

function displayMods(rawMods, rawMask) {
  if (Array.isArray(rawMods) && rawMods.length > 0) {
    return rawMods.join("+")
  }

  if (typeof rawMods === "string" && rawMods.length > 0) {
    return rawMods
  }

  if (typeof rawMask === "number" && rawMask !== 0) {
    const parts = []
    if (rawMask & 1) parts.push("SHIFT")
    if (rawMask & 4) parts.push("CTRL")
    if (rawMask & 8) parts.push("ALT")
    if (rawMask & 64) parts.push("SUPER")
    return parts.join("+")
  }

  return ""
}

// Parse any number of leading metadata tags. `hidden` and `exit` are reserved
// behavior tags; the first other tag is used as the visible category.
function parseDescription(rawDescription) {
  let text = String(rawDescription || "").trim()
  let category = ""
  let hidden = false
  let explicitExit = false

  while (text.length > 0) {
    const match = text.match(/^\[([^\]]*)\]\s*(.*)$/)
    if (!match) break

    const tag = match[1].trim()
    const lowered = tag.toLowerCase()
    if (lowered === "hidden") {
      hidden = true
    } else if (lowered === "exit") {
      explicitExit = true
    } else if (category.length === 0) {
      category = tag
    }
    text = match[2].trim()
  }

  const iconParsed = HyprHelpers.extractIcon(text)
  return {
    category: category,
    hidden: hidden,
    explicitExit: explicitExit,
    icon: iconParsed.icon,
    text: iconParsed.text,
  }
}

function isDispatcherExit(dispatcher, arg) {
  const dispatcherLower = String(dispatcher || "").trim().toLowerCase()
  const argLower = String(arg || "").trim().toLowerCase()
  return dispatcherLower === "submap"
    && (argLower === "reset" || argLower === "default")
}

function bindComparator(a, b) {
  const comboA = String(a.combo || "").toLowerCase()
  const comboB = String(b.combo || "").toLowerCase()
  if (comboA < comboB) return -1
  if (comboA > comboB) return 1

  const actionA = String(a.action || "").toLowerCase()
  const actionB = String(b.action || "").toLowerCase()
  if (actionA < actionB) return -1
  if (actionA > actionB) return 1
  return 0
}

function normalizeBind(item) {
  const record = item || {}
  const submap = HyprHelpers.normalizeSubmapName(record.submap)
  const mods = displayMods(record.mods, record.modmask)
  const hasNamedKey = record.key !== undefined
    && record.key !== null
    && String(record.key).length > 0
  const hasKeycode = typeof record.keycode === "number" && record.keycode > 0
  const keyName = hasNamedKey
    ? String(record.key)
    : (hasKeycode ? "code:" + String(record.keycode) : "?")
  const combo = mods.length > 0 ? (mods + " + " + keyName) : keyName

  const dispatcher = String(record.dispatcher || "")
  const arg = String(record.arg || "")
  const argTrimmed = arg.trim()
  const description = parseDescription(record.description)
  const cleanDescription = description.text

  // A real, conventional unmodified Escape bind remains a compatibility
  // signal for existing Lua callback configurations. Unlike the old fallback,
  // this never creates a key that Hyprland did not report.
  const conventionalEscapeExit = submap.length > 0
    && mods.length === 0
    && HyprHelpers.isEscapeKeyLabel(keyName)
    && cleanDescription.length === 0
  const describedExit = /^exit(?:\s|$)/i.test(cleanDescription)
  const isExit = description.explicitExit
    || isDispatcherExit(dispatcher, arg)
    || describedExit
    || conventionalEscapeExit

  let action = ""
  if (cleanDescription.length > 0) {
    action = cleanDescription
  } else if (isExit) {
    action = "Exit submap"
  } else if (dispatcher.trim().toLowerCase() === "exec") {
    let execCommand = argTrimmed
      .replace(/^uwsm\s+app\s+--\s*/i, "")
      .replace(/\s+/g, " ")
      .trim()
    action = execCommand.toLowerCase().startsWith("hyprctl")
      ? "Unlabelled Hyprland action"
      : (execCommand.length > 0 ? execCommand : "Unlabelled command")
  } else if (dispatcher.trim().toLowerCase() === "__lua") {
    action = "Unlabelled Lua action"
  } else {
    action = dispatcher
    if (argTrimmed.length > 0) {
      action = action.length > 0 ? (action + " " + argTrimmed) : argTrimmed
    }
    if (action.length === 0) {
      action = "Unlabelled action"
    }
  }

  return {
    submap: submap,
    combo: combo,
    action: action,
    category: description.category,
    icon: description.icon,
    hidden: description.hidden,
    isExit: isExit,
  }
}

function groupBinds(items) {
  const exitBinds = []
  const categoryMap = Object.create(null)

  for (const bind of (Array.isArray(items) ? items : [])) {
    if (bind.isExit) {
      exitBinds.push(bind)
      continue
    }

    const category = String(bind.category || "")
    if (!Object.prototype.hasOwnProperty.call(categoryMap, category)) {
      categoryMap[category] = []
    }
    categoryMap[category].push(bind)
  }

  const sortedCategories = Object.keys(categoryMap).sort((a, b) => {
    if (a === "" && b !== "") return -1
    if (a !== "" && b === "") return 1
    return a.toLowerCase().localeCompare(b.toLowerCase())
  })

  const groups = sortedCategories.map((category) => ({
    category: category,
    isExitGroup: false,
    binds: categoryMap[category].slice().sort(bindComparator),
  }))

  if (exitBinds.length > 0) {
    groups.push({
      category: "",
      isExitGroup: true,
      binds: exitBinds.slice().sort(bindComparator),
    })
  }

  return groups
}

function buildIndex(parsed) {
  const flatBySubmap = Object.create(null)

  for (const item of (Array.isArray(parsed) ? parsed : [])) {
    const normalized = normalizeBind(item)
    if (normalized.hidden) continue

    const key = normalized.submap
    if (!Object.prototype.hasOwnProperty.call(flatBySubmap, key)) {
      flatBySubmap[key] = []
    }
    flatBySubmap[key].push(normalized)
  }

  const index = Object.create(null)
  for (const key of Object.keys(flatBySubmap)) {
    index[key] = groupBinds(flatBySubmap[key])
  }
  return index
}

function bindsForSubmap(index, submapName) {
  const key = HyprHelpers.normalizeSubmapName(submapName)
  if (key.length === 0 || !index) return []
  return Object.prototype.hasOwnProperty.call(index, key) ? index[key] : []
}
