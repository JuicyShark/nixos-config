.pragma library

function bindCount(groups) {
  if (!Array.isArray(groups)) return 0

  let total = 0
  for (const group of groups) {
    if (Array.isArray(group.binds)) {
      total += group.binds.length
    }
  }
  return total
}

function maxColumnsForCount(count, minColumns, maxColumns, twoColumnThreshold, fourColumnThreshold) {
  if (count >= fourColumnThreshold) return maxColumns
  if (count <= twoColumnThreshold) return Math.max(1, Math.min(maxColumns, 2))
  return Math.max(minColumns, Math.min(maxColumns, 3))
}

function columnsForWidth(width, count, minColumns, maxColumns, twoColumnThreshold, fourColumnThreshold, minCardWidth, outerMargin) {
  const effectiveMax = maxColumnsForCount(
    count,
    minColumns,
    maxColumns,
    twoColumnThreshold,
    fourColumnThreshold,
  )

  if (width <= 0) return minColumns

  const available = width - outerMargin * 2
  if (available <= 0) return minColumns

  return Math.max(minColumns, Math.min(effectiveMax, Math.floor(available / minCardWidth)))
}

function buildRowModel(groups, columns, submap) {
  if (!Array.isArray(groups) || columns < 1) return []

  const rows = []
  for (const group of groups) {
    const binds = Array.isArray(group.binds) ? group.binds : []
    if (binds.length === 0) continue

    if (!group.isExitGroup) {
      const label = (group.category && group.category.length > 0)
        ? group.category
        : String(submap || "")
      const isDuplicate = label.toLowerCase() === String(submap || "").toLowerCase()
      if (!isDuplicate) {
        rows.push({ type: "header", label: label })
      }
    }

    for (let i = 0; i < binds.length; i += columns) {
      rows.push({
        type: "bindrow",
        binds: binds.slice(i, Math.min(i + columns, binds.length)),
      })
    }
  }

  return rows
}

function rowCounts(rows) {
  const counts = { headers: 0, bindRows: 0, spacers: 0 }
  if (!Array.isArray(rows)) return counts

  for (let i = 0; i < rows.length; i++) {
    if (rows[i].type === "header") {
      counts.headers++
      if (i > 0) counts.spacers++
    } else if (rows[i].type === "bindrow") {
      counts.bindRows++
    }
  }

  return counts
}

function panelMeasurements(groups, columns, submap, maxHeight, metrics) {
  const rows = buildRowModel(groups, columns, submap)
  const counts = rowCounts(rows)
  const desired = metrics.submapHeaderH
    + metrics.outerMargin * 2
    + metrics.footerReserve
    + counts.spacers * metrics.spacerH
    + counts.headers * metrics.headerH
    + counts.bindRows * metrics.cardH
  const minHeight = metrics.submapHeaderH
    + metrics.outerMargin * 2
    + metrics.footerReserve
    + metrics.cardH

  return {
    desired: desired,
    minimum: minHeight,
    clamped: Math.max(minHeight, Math.min(maxHeight, desired)),
    overflows: desired > maxHeight,
  }
}

function panelHeight(groups, columns, submap, maxHeight, metrics) {
  return panelMeasurements(groups, columns, submap, maxHeight, metrics).clamped
}
