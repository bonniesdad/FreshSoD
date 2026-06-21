function FreshSoD_EnsureLocalCharacterVerificationDB()
  if not FRESH_SOD_DB then
    FRESH_SOD_DB = {}
  end

  if not FRESH_SOD_DB.localCharacterVerification then
    FRESH_SOD_DB.localCharacterVerification = {}
  end
end

local function normalizeCharacterName(playerName)
  if not playerName then
    return nil
  end

  return string.lower(Ambiguate(playerName, 'short'))
end

function FreshSoD_SetLocalCharacterVerificationStatus(playerName, isVerified, guildName)
  FreshSoD_EnsureLocalCharacterVerificationDB()

  local shortName = normalizeCharacterName(playerName)
  if not shortName then
    return false
  end

  FRESH_SOD_DB.localCharacterVerification[shortName] = {
    isVerified = isVerified,
    guildName = guildName,
  }

  return true
end

function FreshSoD_GetLocalCharacterVerificationStatus(playerName, guildName)
  FreshSoD_EnsureLocalCharacterVerificationDB()

  local shortName = normalizeCharacterName(playerName)
  if not shortName then
    return nil
  end

  local entry = FRESH_SOD_DB.localCharacterVerification[shortName]
  if not entry then
    return nil
  end

  if guildName and entry.guildName and entry.guildName ~= guildName then
    return nil
  end

  return entry.isVerified
end

function FreshSoD_IsLocalAccountCharacter(playerName)
  FreshSoD_EnsureLocalCharacterVerificationDB()

  local shortName = normalizeCharacterName(playerName)
  if not shortName then
    return false
  end

  return FRESH_SOD_DB.localCharacterVerification[shortName] ~= nil
end
