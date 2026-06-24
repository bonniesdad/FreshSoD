local ADDON_PREFIX = 'FreshSoD'

function FreshSoD_SendDeathTaxLeaderboardSync(playerName, totalCopper)
  if not IsInGuild() then
    return false
  end

  if not FreshSoD_IsDeathTaxGuild() then
    return false
  end

  if not playerName or totalCopper == nil then
    return false
  end

  local message = 'DL:' .. math.max(tonumber(totalCopper) or 0, 0) .. ':' .. playerName
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'GUILD')
  return true
end

local loginLeaderboardSyncSent = false

function FreshSoD_BroadcastDeathTaxLeaderboardSync()
  if not IsInGuild() then
    return false
  end

  if not FreshSoD_IsDeathTaxGuild() then
    return false
  end

  FreshSoD_SyncLocalDeathTaxLeaderboardEntry()

  local playerName = UnitName('player')
  if not playerName then
    return false
  end

  return FreshSoD_SendDeathTaxLeaderboardSync(playerName, FreshSoD_GetDeathTaxTotalAccumulatedCopper())
end

local function tryLoginLeaderboardSync()
  if loginLeaderboardSyncSent then
    return
  end

  if FreshSoD_BroadcastDeathTaxLeaderboardSync() then
    loginLeaderboardSyncSent = true
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
    scheduleLoginLeaderboardSync(3)
    return
  end

  if not loginLeaderboardSyncSent then
    tryLoginLeaderboardSync()
  end
end)
