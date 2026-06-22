local DEATH_TAX_GUILDS = {
  shockstate = true,
  shockstated = true,
}

function FreshSoD_IsDeathTaxGuild()
  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    return false
  end

  return DEATH_TAX_GUILDS[string.lower(guildName)] == true
end
