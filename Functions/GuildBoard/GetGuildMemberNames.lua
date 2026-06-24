local cachedMembers
local cachedGuildName

function FreshSoD_InvalidateGuildMemberNamesCache()
  cachedMembers = nil
  cachedGuildName = nil
end

function FreshSoD_GetGuildMemberNames(forceRefresh, skipRosterRefresh)
  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    FreshSoD_InvalidateGuildMemberNamesCache()
    return {}
  end

  if not forceRefresh and cachedMembers and cachedGuildName == guildName then
    return cachedMembers
  end

  if not skipRosterRefresh then
    FreshSoD_RefreshGuildRoster()
  end

  local members = {}
  local numMembers = GetNumGuildMembers()

  for index = 1, numMembers do
    local name = GetGuildRosterInfo(index)
    if name then
      members[#members + 1] = Ambiguate(name, 'short')
    end
  end

  table.sort(members)
  cachedMembers = members
  cachedGuildName = guildName
  return members
end
