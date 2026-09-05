--!strict

local CACHE_TTL_MS = 60 * 1000
local MAX_RESULTS = 50

type Game = {
  appid: string,
  name: string,
  icon: string?,
}

type SearchResult = {
  id: string,
  title: string,
  subtitle: string,
  glyph: string,
  icon: string?,
  score: number,
}

local games: { Game } = {}
local gamesByAppid: { [string]: Game } = {}
local lastScanMs = 0

local function joinPath(left: string, right: string): string
  return left:gsub("/+$", "") .. "/" .. right:gsub("^/+", "")
end

local function addUnique(values: { string }, seen: { [string]: boolean }, value: string?)
  if value and value ~= "" and not seen[value] then
    seen[value] = true
    table.insert(values, value)
  end
end

local function vdfString(contents: string, key: string): string?
  local pattern = '"' .. key .. '"%s+"([^"\r\n]*)"'
  local value = contents:match(pattern)
  if not value then
    return nil
  end

  return (value:gsub('\\"', '"'):gsub("\\\\", "\\"))
end

local function steamHomes(): { string }
  local home = noctalia.getenv("HOME") or ""
  local candidates = {
    joinPath(home, ".local/share/Steam"),
    joinPath(home, ".steam/steam"),
    joinPath(home, ".var/app/com.valvesoftware.Steam/data/Steam"),
  }
  local found = {}
  local seen = {}

  for _, candidate in candidates do
    if noctalia.fileExists(joinPath(candidate, "steamapps/libraryfolders.vdf")) then
      addUnique(found, seen, candidate)
    end
  end

  return found
end

local function libraryRoots(steamHome: string): { string }
  local roots = { steamHome }
  local seen = { [steamHome] = true }
  local contents = noctalia.readFile(joinPath(steamHome, "steamapps/libraryfolders.vdf"))

  if contents then
    for path in contents:gmatch('"path"%s+"([^"\r\n]+)"') do
      addUnique(roots, seen, path:gsub("\\\\", "\\"))
    end
  end

  return roots
end

local function isGame(name: string): boolean
  local normalized = name:lower()
  return not normalized:match("^proton ")
    and not normalized:match("^steam linux runtime")
    and normalized ~= "steamworks common redistributables"
end

local function gameIcon(steamHome: string, appid: string): string?
  local cacheDir = joinPath(steamHome, "appcache/librarycache/" .. appid)
  local preferred = {
    "library_600x900.jpg",
    "header.jpg",
  }

  for _, filename in preferred do
    local path = joinPath(cacheDir, filename)
    if noctalia.fileExists(path) then
      return path
    end
  end

  local entries = noctalia.listDir(cacheDir)
  if entries then
    for _, filename in entries do
      if filename:match("^[0-9a-fA-F]+%.jpg$") then
        return joinPath(cacheDir, filename)
      end
    end
  end

  return nil
end

local function readGame(manifestPath: string, steamHome: string): Game?
  local contents = noctalia.readFile(manifestPath)
  if not contents then
    return nil
  end

  local appid = vdfString(contents, "appid")
  local name = vdfString(contents, "name")
  if not appid or not appid:match("^%d+$") or not name or name == "" or not isGame(name) then
    return nil
  end

  return {
    appid = appid,
    name = name,
    icon = gameIcon(steamHome, appid),
  }
end

local function scanGames()
  local found: { [string]: Game } = {}

  for _, steamHome in steamHomes() do
    for _, library in libraryRoots(steamHome) do
      local steamapps = joinPath(library, "steamapps")
      local entries = noctalia.listDir(steamapps)
      if entries then
        for _, filename in entries do
          if filename:match("^appmanifest_%d+%.acf$") then
            local game = readGame(joinPath(steamapps, filename), steamHome)
            if game then
              found[game.appid] = game
            end
          end
        end
      end
    end
  end

  games = {}
  gamesByAppid = found
  for _, game in found do
    table.insert(games, game)
  end
  table.sort(games, function(left: Game, right: Game)
    return left.name:lower() < right.name:lower()
  end)
  lastScanMs = noctalia.nowMs()
end

local function ensureGamesAreFresh()
  local now = noctalia.nowMs()
  if lastScanMs == 0 or now - lastScanMs >= CACHE_TTL_MS then
    scanGames()
  end
end

function onQuery(query: string)
  ensureGamesAreFresh()

  local text = noctalia.string.trim(query)
  local results: { SearchResult } = {}

  for _, game in games do
    local score = if text == "" then 0 else noctalia.fuzzyScore(text, game.name .. " " .. game.appid)
    if score ~= nil then
      local result: SearchResult = {
        id = game.appid,
        title = game.name,
        subtitle = "Steam AppID " .. game.appid,
        glyph = "brand-steam",
        icon = game.icon,
        score = score,
      }
      table.insert(results, result)
    end
  end

  table.sort(results, function(left: SearchResult, right: SearchResult)
    if left.score == right.score then
      return left.title:lower() < right.title:lower()
    end
    return left.score > right.score
  end)

  while #results > MAX_RESULTS do
    table.remove(results)
  end

  if #results == 0 then
    if #games == 0 then
      results[1] = {
        id = "",
        title = "No installed Steam games found",
        subtitle = "Checked Steam's configured library folders",
        glyph = "brand-steam",
        score = 0,
      }
    else
      results[1] = {
        id = "",
        title = "No matching Steam games",
        subtitle = text,
        glyph = "search-off",
        score = 0,
      }
    end
  end

  launcher.setResults(query, results)
end

function onActivate(appid: string)
  if appid == "" or not gamesByAppid[appid] then
    return
  end

  if not noctalia.runAsync({ "steam", "-applaunch", appid }) then
    noctalia.notifyError("Steam Games", "Could not start Steam AppID " .. appid)
  end
end
