local mailRestrictionFrame = CreateFrame('Frame')
local pendingMailCheck = nil
local inboxScanPending = false

function FreshSoD_IsMailInboxScanPending()
  return inboxScanPending
end

function FreshSoD_SetMailInboxScanPending(isPending)
  inboxScanPending = isPending and true or false
end

local function cancelPendingMailCheck()
  if pendingMailCheck then
    pendingMailCheck:Cancel()
    pendingMailCheck = nil
  end
end

local scheduleMailRestrictionUpdate

local function beginMailboxOpen()
  FreshSoD_SetMailInboxScanPending(true)
  FreshSoD_PreemptivelyBlockOpenAllMail()
  scheduleMailRestrictionUpdate()
end

local function completeMailboxInboxScan()
  if inboxScanPending then
    FreshSoD_SetMailInboxScanPending(false)
  end

  FreshSoD_UpdateMailRestrictionOverlay()
end

scheduleMailRestrictionUpdate = function()
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
    hooksecurefunc('InboxFrame_Update', completeMailboxInboxScan)
  end
end

local function hookOpenAllMail()
  if not OpenAllMail or OpenAllMail.freshSoDOpenAllHooked then
    return
  end

  OpenAllMail.freshSoDOpenAllHooked = true

  if OpenAllMailMixin and OpenAllMailMixin.StartOpening then
    hooksecurefunc(OpenAllMailMixin, 'StartOpening', function(self)
      if FreshSoD_ShouldBlockOpenAllMail() then
        self:StopOpening()
        self:Disable()
        FreshSoD_UpdateMailRestrictionOverlay()
      end
    end)
  end
end

local function hookMailFrame()
  if not MailFrame or MailFrame.freshSoDMailHooked then
    return
  end

  MailFrame.freshSoDMailHooked = true
  MailFrame:HookScript('OnShow', scheduleMailRestrictionUpdate)
  hookInboxFrameUpdate()
  hookOpenAllMail()
  FreshSoD_EnsureMailOpenAllBlocker()
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
    FreshSoD_SetMailInboxScanPending(false)
    FreshSoD_HideMailRestrictionOverlay()
    return
  end

  if event == 'MAIL_SHOW' then
    beginMailboxOpen()
    return
  end

  if event == 'GUILD_ROSTER_UPDATE' then
    scheduleMailRestrictionUpdate()
    return
  end

  if event == 'MAIL_INBOX_UPDATE' then
    completeMailboxInboxScan()
    return
  end

  FreshSoD_UpdateMailRestrictionOverlay()
end)

hookMailFrame()
hookInboxFrameUpdate()
hookOpenAllMail()
FreshSoD_EnsureMailOpenAllBlocker()
