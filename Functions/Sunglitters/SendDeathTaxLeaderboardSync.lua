local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendDeathTaxLeaderboardSync(playerName, totalCopper)
  if not IsInGuild() or not FreshSoD_IsDeathTaxGuild() then
    return
  end

  if not playerName or totalCopper == nil then
    return
  end

  local message = 'DL:' .. math.max(tonumber(totalCopper) or 0, 0) .. ':' .. playerName
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'GUILD')
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
