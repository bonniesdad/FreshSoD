local OFFICER_RANK_INDEX_MAX = 2

local function getGuildRankIndex(playerName)
  if not playerName or not IsInGuild() then
    return nil
  end

  FreshSoD_RefreshGuildRoster()

  local targetName = Ambiguate(playerName, 'short')
  local numMembers = GetNumGuildMembers()

  for index = 1, numMembers do
    local name, _, rankIndex = GetGuildRosterInfo(index)
    if name and Ambiguate(name, 'short') == targetName then
      return rankIndex
    end
  end

  return nil
end

function FreshSoD_IsOfficerGuildRank(playerName)
  local rankIndex = getGuildRankIndex(playerName)
  if rankIndex == nil then
    return false
  end

  return rankIndex <= OFFICER_RANK_INDEX_MAX
end

function FreshSoD_AmIOfficerGuildRank()
  local playerName = UnitName('player')
  if not playerName then
    return false
  end

  return FreshSoD_IsOfficerGuildRank(playerName)
end
