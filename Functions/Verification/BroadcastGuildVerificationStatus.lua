local lastBroadcastStatus = nil

function FreshSoD_BroadcastGuildVerificationStatusIfChanged(force)
  if not IsInGuild() then
    lastBroadcastStatus = nil
    return
  end

  if FreshSoD_UpdateBuffVerification then
    FreshSoD_UpdateBuffVerification()
  end

  local isVerified = FreshSoD_AmIVerified()
  local guildName = FreshSoD_GetPlayerGuildName()

  if guildName then
    FreshSoD_SetLocalCharacterVerificationStatus(UnitName('player'), isVerified, guildName)
    FreshSoD_SetGuildMemberVerificationStatus(guildName, UnitName('player'), isVerified)
  end

  if not force and lastBroadcastStatus == isVerified then
    return
  end

  FreshSoD_SendGuildVerificationStatus(isVerified)
  lastBroadcastStatus = isVerified
end

function FreshSoD_ReplyWithGuildVerificationStatus()
  lastBroadcastStatus = nil
  FreshSoD_BroadcastGuildVerificationStatusIfChanged()
end

local broadcastFrame = CreateFrame('Frame')
broadcastFrame:RegisterEvent('PLAYER_LOGIN')
broadcastFrame:RegisterEvent('PLAYER_GUILD_UPDATE')

broadcastFrame:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_LOGIN' then
    if C_Timer and C_Timer.After then
      C_Timer.After(2, FreshSoD_BroadcastGuildVerificationStatusIfChanged)
    else
      FreshSoD_BroadcastGuildVerificationStatusIfChanged()
    end
    return
  end

  FreshSoD_BroadcastGuildVerificationStatusIfChanged()
end)
