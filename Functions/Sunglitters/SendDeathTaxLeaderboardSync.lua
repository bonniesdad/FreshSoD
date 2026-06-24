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

local loginLeaderboardSyncSent = false

function FreshSoD_BroadcastDeathTaxLeaderboardSync()
  if not IsInGuild() then
    FreshSoD_LogDeathTax('Leaderboard broadcast skipped: not in guild')
    return false
  end

  if not FreshSoD_IsDeathTaxGuild() then
    FreshSoD_LogDeathTax('Leaderboard broadcast skipped: not a death tax guild (guild=' .. tostring(FreshSoD_GetPlayerGuildName and FreshSoD_GetPlayerGuildName()) .. ')')
    return false
  end

  FreshSoD_SyncLocalDeathTaxLeaderboardEntry()

  local playerName = UnitName('player')
  if not playerName then
    FreshSoD_LogDeathTax('Leaderboard broadcast skipped: no player name')
    return false
  end

  local totalCopper = FreshSoD_GetDeathTaxTotalAccumulatedCopper()
  local owedCopper = FreshSoD_GetDeathTaxOwedCopper()
  FreshSoD_LogDeathTax(
    'Leaderboard broadcast: owed=' .. tostring(owedCopper) .. 'c total=' .. tostring(totalCopper) .. 'c'
  )

  return FreshSoD_SendDeathTaxLeaderboardSync(playerName, totalCopper)
end

local function tryLoginLeaderboardSync()
  if loginLeaderboardSyncSent then
    return
  end

  if FreshSoD_BroadcastDeathTaxLeaderboardSync() then
    loginLeaderboardSyncSent = true
    FreshSoD_LogDeathTax('Login leaderboard sync complete')
  end
end

local function scheduleLoginLeaderboardSync(delay)
  if C_Timer and C_Timer.After then
    C_Timer.After(delay, tryLoginLeaderboardSync)
  else
    tryLoginLeaderboardSync()
  end
end

local leaderboardSyncFrame = CreateFrame('Frame')
leaderboardSyncFrame:RegisterEvent('PLAYER_LOGIN')
leaderboardSyncFrame:RegisterEvent('PLAYER_GUILD_UPDATE')
leaderboardSyncFrame:RegisterEvent('GUILD_ROSTER_UPDATE')

leaderboardSyncFrame:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_LOGIN' then
    loginLeaderboardSyncSent = false
    FreshSoD_LogDeathTax('Scheduling login leaderboard sync')
    scheduleLoginLeaderboardSync(3)
    return
  end

  if not loginLeaderboardSyncSent then
    tryLoginLeaderboardSync()
  end
end)
