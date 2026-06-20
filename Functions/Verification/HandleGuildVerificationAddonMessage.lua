local ADDON_PREFIX = 'FreshSoD'

-- Holding pen for statuses that show up before the roster has actually loaded.
-- we cant confirm the sender is a real guildie yet so instead of chucking the
-- message in the bin (which is exactly how we ended up needing /reload in the first place) we stash it and have another go on the next GUILD_ROSTER_UPDATE.
local pendingGuildVerification = {}

local function applyGuildVerification(sender, isVerified)
  if not FreshSoD_IsPlayerInGuildRoster(sender) then
    -- Only babysit this while the roster is still waking up. If its warm and we STILL cant find the sender then they're just not in our guild, so let it go
    -- instead of re-queueing the same dude forever like a clingy and batshit fuckin exgf.
    if type(FreshSoD_IsGuildRosterReady) == 'function' and not FreshSoD_IsGuildRosterReady() then
      pendingGuildVerification[sender] = isVerified
      FreshSoD_RefreshGuildRoster()
    else
      pendingGuildVerification[sender] = nil
    end
    return
  end

  pendingGuildVerification[sender] = nil

  local guildName = FreshSoD_GetPlayerGuildName()
  if not guildName then
    return
  end

  FreshSoD_SetGuildMemberVerificationStatus(guildName, sender, isVerified)

  if FreshSoD_RefreshGuildBoardTabIfVisible then
    FreshSoD_RefreshGuildBoardTabIfVisible()
  end
end

local addonMessageFrame = CreateFrame('Frame')
addonMessageFrame:RegisterEvent('CHAT_MSG_ADDON')
addonMessageFrame:RegisterEvent('GUILD_ROSTER_UPDATE')

addonMessageFrame:SetScript('OnEvent', function(_, event, ...)
  if event == 'GUILD_ROSTER_UPDATE' then
    if next(pendingGuildVerification) then
      local queued = pendingGuildVerification
      pendingGuildVerification = {}
      for sender, isVerified in pairs(queued) do
        applyGuildVerification(sender, isVerified)
      end
    end
    return
  end

  -- alright, its a CHAT_MSG_ADDON lets see whats going on
  local prefix, message, channel, sender = ...
  if prefix ~= ADDON_PREFIX or not sender then
    return
  end

  -- take it from the guild broadcast OR a direct whisper reply we aint picky
  if channel ~= 'GUILD' and channel ~= 'WHISPER' then
    return
  end

  -- Somebody is asking what our status is. Whisper it straight back to just them and bail. Also ignore our own request bouncing back at us, no point whisperin ourselves like a weirdo.
  if FreshSoD_ParseGuildVerificationRequest and FreshSoD_ParseGuildVerificationRequest(message) then
    local isSelf = FreshSoD_PlayerNamesMatch and FreshSoD_PlayerNamesMatch(sender, UnitName('player'))
    if not isSelf and FreshSoD_ReplyGuildVerificationStatus then
      FreshSoD_ReplyGuildVerificationStatus(sender)
    end
    return
  end

  local isVerified = FreshSoD_ParseGuildVerificationMessage(message)
  if isVerified == nil then
    return
  end

  applyGuildVerification(sender, isVerified)
end)
