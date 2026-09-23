.pragma library

function normalizeSubmapName(name) {
  if (!name) {
    return ""
  }

  const trimmed = String(name).trim()
  const lowered = trimmed.toLowerCase()
  if (lowered === "reset" || lowered === "default") {
    return ""
  }

  return trimmed
}

function isEscapeKeyLabel(label) {
  const key = String(label || "").trim().toLowerCase()
  return key === "escape" || key === "esc"
}

// Extract a leading Nerd Font glyph from text.
// Nerd Fonts occupy the Unicode Private Use Area (U+E000-U+F8FF) on the
// Basic Multilingual Plane.  If the very first code point of `text` falls
// in that range it is treated as an icon and separated from the rest of
// the string.
// Returns { icon: string, text: string } where icon is "" when absent.
function extractIcon(text) {
  const str = String(text || "")
  if (str.length === 0) {
    return { icon: "", text: str }
  }

  const code = str.codePointAt(0)
  if ((code >= 0xE000 && code <= 0xF8FF) || (code >= 0xF0000 && code <= 0xFFFFD)) {
    const iconChar = String.fromCodePoint(code)
    const rest = str.slice(iconChar.length).replace(/^\s+/, "")
    return { icon: iconChar, text: rest }
  }

  return { icon: "", text: str }
}
