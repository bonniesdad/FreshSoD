local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendDeathTaxLeaderboardSync(playerName, totalCopper)
  if not IsInGuild() then
    FreshSoD_LogDeathTax('DL send skipped: not in guild')
    return false
  end

  if not FreshSoD_IsDeathTaxGuild() then
    FreshSoD_LogDeathTax('DL send skipped: not a death tax guild')
    return false
  end

  if not playerName or totalCopper == nil then
    FreshSoD_LogDeathTax('DL send skipped: invalid args (player=' .. tostring(playerName) .. ', total=' .. tostring(totalCopper) .. ')')
    return false
  end

  local message = 'DL:' .. math.max(tonumber(totalCopper) or 0, 0) .. ':' .. playerName
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'GUILD')
  FreshSoD_LogDeathTax('DL sent: ' .. message)
  return true
end

function FreshSoD_BroadcastDeathTaxLeaderboardSync()
  if not FreshSoD_IsDeathTaxGuild() then
    return
  end

  FreshSoD_SyncLocalDeathTaxLeaderboardEntry()

  local playerName = UnitName('player')
  if not playerName then
    return
  end

  FreshSoD_SendDeathTaxLeaderboardSync(playerName, FreshSoD_GetDeathTaxTotalAccumulatedCopper())
end

local leaderboardSyncFrame = CreateFrame('Frame')
leaderboardSyncFrame:RegisterEvent('PLAYER_LOGIN')

leaderboardSyncFrame:SetScript('OnEvent', function()
  if not FreshSoD_IsDeathTaxGuild() then
    return
  end

  if C_Timer and C_Timer.After then
    C_Timer.After(3, FreshSoD_BroadcastDeathTaxLeaderboardSync)
  else
    FreshSoD_BroadcastDeathTaxLeaderboardSync()
  end
end)
