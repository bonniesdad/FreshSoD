function FreshSoD_IsTopGuildRank(playerName)
  if not playerName or not IsInGuild() then
    return false
  end

  -- reaaad the rank from the shared roster cache (O(1)) rather than rescanning the
  -- roster synchroously after an async request.
  FreshSoD_RefreshGuildRoster()

  local rankIndex = FreshSoD_GetGuildRosterCacheRank(playerName)
  if rankIndex == nil then
    return false
  end

  return rankIndex == 0 or rankIndex == 1
end

function FreshSoD_AmITopGuildRank()
  local playerName = UnitName('player')
  if not playerName then
    return false
  end

  return FreshSoD_IsTopGuildRank(playerName)
end
