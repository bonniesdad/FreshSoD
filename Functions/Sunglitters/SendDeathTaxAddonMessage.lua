local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendDeathTaxAddonMessage(playerName, taxCopper)
  if not IsInGuild() then
    return false
  end

  if not FreshSoD_IsDeathTaxGuild() then
    return false
  end

  local message = 'DT:' .. taxCopper .. ':' .. playerName
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'GUILD')
  return true
end
