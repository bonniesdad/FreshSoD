local function normalizeGuildName(guildName)
  if not guildName then
    return nil
  end
  
  return string.lower(guildName)
end

function FreshSoD_IsWhitelistedGuild(guildName)
  if not guildName then
    return false
  end

  local whitelist = BONNIES_UTILITIES_GUILD_FOUND_WHITELISTED_GUILDS
  if type(whitelist) ~= 'table' then
    -- The whitelist lives over in BonniesUtilities and might not exist yet if the load order is being moody. Just say "nope, no whitelist" instead of blowing up
    -- trying to loop over a nil.
    return false
  end

  local normalizedGuildName = normalizeGuildName(guildName)
  for _, whitelistedGuild in ipairs(whitelist) do
    if normalizeGuildName(whitelistedGuild) == normalizedGuildName then
      return true
    end
  end

  return false
end
