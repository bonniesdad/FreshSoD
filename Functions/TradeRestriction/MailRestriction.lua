local mailRestrictionFrame = CreateFrame('Frame')
local pendingMailCheck = nil

local function cancelPendingMailCheck()
  if pendingMailCheck then
    pendingMailCheck:Cancel()
    pendingMailCheck = nil
  end
end

local function scheduleMailRestrictionUpdate()
  cancelPendingMailCheck()
  FreshSoD_UpdateMailRestrictionOverlay()

  if not C_Timer or not C_Timer.After then
    return
  end

  pendingMailCheck = C_Timer.After(0, function()
    pendingMailCheck = nil
    FreshSoD_UpdateMailRestrictionOverlay()
  end)
end

local function hookInboxFrameUpdate()
  if InboxFrame_Update and not _G.FreshSoDInboxFrameUpdateHooked then
    _G.FreshSoDInboxFrameUpdateHooked = true
    hooksecurefunc('InboxFrame_Update', FreshSoD_UpdateMailRestrictionOverlay)
  end
end

local function hookMailFrame()
  if not MailFrame or MailFrame.freshSoDMailHooked then
    return
  end

  MailFrame.freshSoDMailHooked = true
  MailFrame:HookScript('OnShow', scheduleMailRestrictionUpdate)
  hookInboxFrameUpdate()
end

mailRestrictionFrame:RegisterEvent('PLAYER_LOGIN')
mailRestrictionFrame:RegisterEvent('MAIL_SHOW')
mailRestrictionFrame:RegisterEvent('MAIL_INBOX_UPDATE')
mailRestrictionFrame:RegisterEvent('MAIL_CLOSED')
mailRestrictionFrame:RegisterEvent('GUILD_ROSTER_UPDATE')

mailRestrictionFrame:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_LOGIN' then
    hookMailFrame()
    return
  end

  if event == 'MAIL_CLOSED' then
    cancelPendingMailCheck()
    FreshSoD_HideMailRestrictionOverlay()
    return
  end

  if event == 'MAIL_SHOW' or event == 'GUILD_ROSTER_UPDATE' then
    scheduleMailRestrictionUpdate()
    return
  end

  FreshSoD_UpdateMailRestrictionOverlay()
end)

hookMailFrame()
hookInboxFrameUpdate()
