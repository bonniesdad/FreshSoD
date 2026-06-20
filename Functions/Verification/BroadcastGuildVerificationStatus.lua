local lastBroadcastStatus = nil
local hasRequestedPeerStatus = false

function FreshSoD_BroadcastGuildVerificationStatusIfChanged()
  if not IsInGuild() then
    lastBroadcastStatus = nil
    return
  end

  if FreshSoD_UpdateBuffVerification then
    FreshSoD_UpdateBuffVerification()
  end

  local isVerified = FreshSoD_AmIVerified()
  local guildName = FreshSoD_GetPlayerGuildName()

  -- Right after login the guild data is usually still nil, because Blizzard. Dont do anything yet and do NOT latch lastBroadcastStatus or we'll happily remember a
  -- bogus "nothing" forever. We're hooked up to GUILD_ROSTER_UPDATE too, so this runs
  -- again the moment the data actually decides to show up.
  if not guildName then
    return
  end

  FreshSoD_SetLocalCharacterVerificationStatus(UnitName('player'), isVerified, guildName)
  FreshSoD_SetGuildMemberVerificationStatus(guildName, UnitName('player'), isVerified)

  if lastBroadcastStatus ~= isVerified then
    FreshSoD_SendGuildVerificationStatus(isVerified)
    lastBroadcastStatus = isVerified
  end

  -- Ask everyone once for their status so we catch up even if they all announced
  -- themselves before we logged in. They whisper it back to us nice and private.
  if not hasRequestedPeerStatus and FreshSoD_SendGuildVerificationRequest then
    FreshSoD_SendGuildVerificationRequest()
    hasRequestedPeerStatus = true
  end

  if FreshSoD_RefreshGuildBoardTabIfVisible then
    FreshSoD_RefreshGuildBoardTabIfVisible()
  end
end

local broadcastFrame = CreateFrame('Frame')
broadcastFrame:RegisterEvent('PLAYER_LOGIN')
broadcastFrame:RegisterEvent('PLAYER_GUILD_UPDATE')
broadcastFrame:RegisterEvent('GUILD_ROSTER_UPDATE')

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
