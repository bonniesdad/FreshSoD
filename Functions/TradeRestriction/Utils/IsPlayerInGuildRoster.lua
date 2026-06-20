function FreshSoD_IsPlayerInGuildRoster(playerName)
  if not playerName or not IsInGuild() then
    return false
  end

  -- nudge a throttled async refresh so the cache stays ready for action then answer from the cache (O(1))
  FreshSoD_RefreshGuildRoster()

  return FreshSoD_IsNameInGuildRosterCache(playerName)
end
