local function normalizeLeaderboardKey(playerName)
  if not playerName then
    return nil
  end

  return string.lower(Ambiguate(playerName, 'short'))
end

function FreshSoD_EnsureDeathTaxLeaderboardDB()
  if not FRESH_SOD_DB then
    FRESH_SOD_DB = {}
  end

  if not FRESH_SOD_DB.deathTaxLeaderboardV2 then
    FRESH_SOD_DB.deathTaxLeaderboardV2 = {}
  end
end

function FreshSoD_SetDeathTaxLeaderboardEntry(playerName, totalCopper)
  FreshSoD_EnsureDeathTaxLeaderboardDB()

  local key = normalizeLeaderboardKey(playerName)
  if not key then
    return
  end

  FRESH_SOD_DB.deathTaxLeaderboardV2[key] = {
    playerName = Ambiguate(playerName, 'short'),
    totalCopper = math.max(tonumber(totalCopper) or 0, 0),
  }
end

function FreshSoD_GetDeathTaxLeaderboardSorted()
  FreshSoD_EnsureDeathTaxLeaderboardDB()

  local entries = {}
  for _, entry in pairs(FRESH_SOD_DB.deathTaxLeaderboardV2) do
    if entry.totalCopper and entry.totalCopper > 0 then
      entries[#entries + 1] = entry
    end
  end

  table.sort(entries, function(a, b)
    if a.totalCopper == b.totalCopper then
      return (a.playerName or '') < (b.playerName or '')
    end
    return a.totalCopper > b.totalCopper
  end)

  return entries
end

function FreshSoD_SyncLocalDeathTaxLeaderboardEntry()
  if not FreshSoD_IsDeathTaxGuild() then
    return
  end

  local playerName = UnitName('player')
  if not playerName then
    return
  end

  FreshSoD_SetDeathTaxLeaderboardEntry(playerName, FreshSoD_GetDeathTaxTotalAccumulatedCopper())
end
