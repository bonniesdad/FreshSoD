local ADDON_NAME = 'FreshSoD'

local commsFrame = CreateFrame('Frame')
commsFrame:RegisterEvent('ADDON_LOADED')
commsFrame:RegisterEvent('PLAYER_LOGIN')
commsFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
commsFrame:RegisterEvent('CHANNEL_UI_UPDATE')
commsFrame:RegisterEvent('CHAT_MSG_CHANNEL')

commsFrame:SetScript('OnEvent', function(_, event, ...)
  if event == 'ADDON_LOADED' then
    if (...) ~= ADDON_NAME then
      return
    end

    FreshSoD_Comms.InstallChannelNoticeFilters()
    FreshSoD_Comms.ScheduleDelayedChannelJoin()
    return
  end

  if event == 'PLAYER_LOGIN' or event == 'PLAYER_ENTERING_WORLD' then
    FreshSoD_Comms.ScheduleDelayedChannelJoin()
    return
  end

  if event == 'CHANNEL_UI_UPDATE' then
    FreshSoD_Comms.EnsureChannelJoined()
    return
  end

  if event == 'CHAT_MSG_CHANNEL' then
    if not FreshSoD_Comms.IsOurChannelMessage(...) then
      return
    end

    if FreshSoD_OnCommsChannelMessage then
      FreshSoD_OnCommsChannelMessage(...)
    end
  end
end)
