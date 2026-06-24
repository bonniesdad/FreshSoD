local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendDeathTaxAddonMessage(playerName, taxCopper)
  if not IsInGuild() then
    FreshSoD_LogDeathTax('DT send skipped: not in guild')
    return false
  end

  if not FreshSoD_IsDeathTaxGuild() then
    FreshSoD_LogDeathTax('DT send skipped: not a death tax guild')
    return false
  end

  local message = 'DT:' .. taxCopper .. ':' .. playerName
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'GUILD')
  FreshSoD_LogDeathTax('DT sent: ' .. message)
  return true
end
