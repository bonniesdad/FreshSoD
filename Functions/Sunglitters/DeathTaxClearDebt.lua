local ADDON_PREFIX = 'FreshSoD'
local CLEAR_DEBT_MESSAGE = 'DC:CLEAR'

local function sendWhisperAddonMessage(targetName, message)
  if not targetName or not message or not FreshSoD_IsDeathTaxGuild() then
    return false
  end

  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, 'WHISPER', targetName)
  return true
end

function FreshSoD_SendDeathTaxClearDebt(targetName)
  if not targetName or not FreshSoD_IsDeathTaxGuild() or not FreshSoD_AmIOfficerGuildRank() then
    return false
  end

  return sendWhisperAddonMessage(targetName, CLEAR_DEBT_MESSAGE)
end

function FreshSoD_HandleDeathTaxClearDebt(sender)
  if not sender or not FreshSoD_IsDeathTaxGuild() then
    return
  end

  if not FreshSoD_IsPlayerInGuildRoster(sender) then
    return
  end

  if not FreshSoD_IsOfficerGuildRank(sender) then
    return
  end

  FreshSoD_ClearDeathTaxOwedCopper()
end

local addonMessageFrame = CreateFrame('Frame')
addonMessageFrame:RegisterEvent('CHAT_MSG_ADDON')

addonMessageFrame:SetScript('OnEvent', function(_, event, ...)
  if event ~= 'CHAT_MSG_ADDON' then
    return
  end

  local prefix, message, channel, sender = ...
  if prefix ~= ADDON_PREFIX or channel ~= 'WHISPER' or not sender then
    return
  end

  if message ~= CLEAR_DEBT_MESSAGE then
    return
  end

  FreshSoD_HandleDeathTaxClearDebt(sender)
end)
