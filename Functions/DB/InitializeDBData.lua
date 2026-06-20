local function deepCopy(value)
  if type(value) ~= 'table' then
    return value
  end

  local copy = {}
  for key, inner in pairs(value) do
    copy[key] = deepCopy(inner)
  end
  return copy
end

function FreshSoD_InitializeDBData()
  if not FRESH_SOD_DB then
    FRESH_SOD_DB = {}
  end

  if not FRESH_SOD_DB.characterSettings then
    FRESH_SOD_DB.characterSettings = {}
  end

  local defaultSettings = {
    minimapButton = { hide = false },
    levelBracketAcknowledged = {},
    deathTaxOwedCopper = 0,
  }

  local characterGUID = UnitGUID('player')
  if not FRESH_SOD_DB.characterSettings[characterGUID] then
    FRESH_SOD_DB.characterSettings[characterGUID] = {}
  end

  local settings = FRESH_SOD_DB.characterSettings[characterGUID]

  -- migrte values writen by older versions that persisted settings to the whatever location FRESH_SOD_DB[GUID]
  local legacySettings = FRESH_SOD_DB[characterGUID]
  if type(legacySettings) == 'table' then
    for settingName, settingValue in pairs(legacySettings) do
      if settings[settingName] == nil then
        settings[settingName] = settingValue
      end
    end
    FRESH_SOD_DB[characterGUID] = nil
  end

  -- backfill missing defaults 
  for settingName, settingValue in pairs(defaultSettings) do
    if settings[settingName] == nil then
      settings[settingName] = deepCopy(settingValue)
    end
  end

  FRESH_SOD_GLOBAL_SETTINGS = settings

  if FreshSoD_EnsureGuildVerificationDB then
    FreshSoD_EnsureGuildVerificationDB()
  end
end
