function FreshSoD_GetTamperingHistory()
  if type(BonniesUtilities_GetDBValue) ~= 'function' then
    return {}
  end

  local naughtyLog = BonniesUtilities_GetDBValue('naughtyLog')
  if not naughtyLog then
    return {}
  end

  return naughtyLog
end
