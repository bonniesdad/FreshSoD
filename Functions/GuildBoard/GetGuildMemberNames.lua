function FreshSoD_GetGuildMemberNames()
  if not IsInGuild() then
    return {}
  end

  FreshSoD_RefreshGuildRoster()

  return FreshSoD_GetGuildRosterCacheNames()
end
