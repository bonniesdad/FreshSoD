function FreshSoD_SendTamperingHistory(playerName)
  if not playerName or playerName == '' then
    return
  end

  if type(BonniesUtilities_WhisperNaughtyLog) ~= 'function' then
    return
  end

  BonniesUtilities_WhisperNaughtyLog(playerName)
end
