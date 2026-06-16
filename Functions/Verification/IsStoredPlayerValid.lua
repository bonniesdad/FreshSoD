function FreshSoD_IsStoredPlayerValid(playerName)
  if not playerName or playerName == '' then
    return false
  end

  return FreshSoD_GetStoredPlayerVerificationStatus(playerName) == true
end
