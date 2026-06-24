local DEATH_TAX_GUILDS = {
  shockstate = true,
  shockstated = true,
}

function FreshSoD_IsDeathTaxGuildName(guildName)
  if not guildName then
    return false
  end

  return DEATH_TAX_GUILDS[string.lower(guildName)] == true
end

function FreshSoD_IsDeathTaxGuild()
  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    return false
  end

  return FreshSoD_IsDeathTaxGuildName(guildName)
end

function FreshSoD_IsUnitInDeathTaxGuild(unit)
  if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
    return false
  end

  local playerName = GetUnitName(unit, true)

  if playerName and FreshSoD_IsPlayerInGuildRoster(playerName) then
    return FreshSoD_IsDeathTaxGuild()
  end

  local guildName = GetGuildInfo(unit)
  if guildName then
    return FreshSoD_IsDeathTaxGuildName(guildName)
  end

  if playerName then
    guildName = GetGuildInfo(playerName)
    if guildName then
      return FreshSoD_IsDeathTaxGuildName(guildName)
    end
  end

  return false
end
