-- This is the mofoing shared guild roster cache.
-- Blizzard, in their infinite wisdom, made GuildRoster() async. Calling it does not actually give you a roster, it politely asks the server for one and then fucks off. The real data shows up later in GUILD_ROSTER_UPDATE whenever Blizzard feels like it.
-- The old code requested the roster and then immediately tried to read it in the same frame. Unsurprisingly that worked about as well as you'd expect. Right after login the roster was often still empty, causing actual guild members to be treated as random strangers until somebody did a /reload and sacrificed a goat to the WoW gods.
-- To avoid that nonsense, this module owns a single cached membership table that gets rebuilt whenever GUILD_ROSTER_UPDATE fires. Everything else should query this cache instead of poking Blizzard's half-baked API directly.
-- Fast lookups, fewer surprises, and one less reason to question Blizzard's life choices.

local ROSTER_REQUEST_THROTTLE_SECONDS = 10

local rosterCache = {}          
local rosterReady = false
local lastRosterRequest = 0
local cachedPlayerGuildName = nil

local function normalize(playerName)
  if not playerName then
    return nil
  end

  return string.lower(Ambiguate(playerName, 'short'))
end

local function requestRoster(force)
  if not (IsInGuild and IsInGuild()) then
    return
  end

  local now = (GetTime and GetTime()) or 0
  if not force and (now - lastRosterRequest) < ROSTER_REQUEST_THROTTLE_SECONDS then
    return
  end
  lastRosterRequest = now

  if SetGuildRosterShowOffline then
    SetGuildRosterShowOffline(true)
  end

  if C_GuildInfo and C_GuildInfo.GuildRoster then
    C_GuildInfo.GuildRoster()
  elseif GuildRoster then
    GuildRoster()
  end
end

-- This request is async because apparently returning data when asked would be too easy.
-- Do NOT expect roster data to exist when this function returns. It only kicks off the request and leaves the actual work to Blizzards event system.
-- If you need guild membership information, use the cache accessors below. Reading the roster directly is how we ended up with this comment section in the first place.

function FreshSoD_RefreshGuildRoster()
  requestRoster(false)
end

local function rebuildCache()
  if not (IsInGuild and IsInGuild()) then
    rosterCache = {}
    rosterReady = false
    cachedPlayerGuildName = nil
    return
  end

  local numMembers = (GetNumGuildMembers and GetNumGuildMembers()) or 0
  if numMembers <= 0 then
    -- Roster has not arrived yet.
    -- Keep whatever data we already have and try again later.
    -- Better to wait a bit longer than to cache an empty roster and spend the next hour wondering why nobody is in the guild.

    requestRoster(false)
    return
  end

  local fresh = {}
  for index = 1, numMembers do
    local name, _, rankIndex = GetGuildRosterInfo(index)
    local key = normalize(name)
    if key then
      fresh[key] = { name = Ambiguate(name, 'short'), rank = rankIndex }
    end
  end

  rosterCache = fresh
  rosterReady = true
  cachedPlayerGuildName = (GetGuildInfo and GetGuildInfo('player')) or cachedPlayerGuildName
end

-- Public accessors 

-- True once the roster has been fetched at least once this session.
function FreshSoD_IsGuildRosterReady()
  return rosterReady
end

function FreshSoD_IsNameInGuildRosterCache(playerName)
  local key = normalize(playerName)
  if not key then
    return false
  end

  return rosterCache[key] ~= nil
end

function FreshSoD_GetGuildRosterCacheRank(playerName)
  local key = normalize(playerName)
  if not key then
    return nil
  end

  local entry = rosterCache[key]
  return entry and entry.rank or nil
end

function FreshSoD_GetGuildRosterCacheNames()
  local names = {}
  for _, entry in pairs(rosterCache) do
    names[#names + 1] = entry.name
  end

  table.sort(names)
  return names
end

local rosterFrame = CreateFrame('Frame')
rosterFrame:RegisterEvent('PLAYER_LOGIN')
rosterFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
rosterFrame:RegisterEvent('PLAYER_GUILD_UPDATE')
rosterFrame:RegisterEvent('GUILD_ROSTER_UPDATE')

rosterFrame:SetScript('OnEvent', function(_, event)
  if event == 'GUILD_ROSTER_UPDATE' then
    rebuildCache()
    return
  end

  -- If the player just logged in or the guild actually changed, grab fresh data immediately.
  -- If they're just zoning around, a throttled refresh is fine. No need to spam requests for that.
  requestRoster(event ~= 'PLAYER_ENTERING_WORLD')
  rebuildCache()
end)
