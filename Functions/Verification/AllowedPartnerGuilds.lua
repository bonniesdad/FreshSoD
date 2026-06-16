function FreshSoD_NormalizeGuildName(guildName)
  if not guildName then
    return nil
  end

  local normalized = guildName:match('^%s*(.-)%s*$')
  if not normalized or normalized == '' then
    return nil
  end

  return string.lower(normalized)
end

function FreshSoD_IsTrustedTradePartner(partnerName)
  if not partnerName then
    return false
  end

  if BonniesUtilities_IsTradePartnerInMyGuild and BonniesUtilities_IsTradePartnerInMyGuild() then
    return true
  end

  return FreshSoD_IsStoredPlayerValid(partnerName)
end
