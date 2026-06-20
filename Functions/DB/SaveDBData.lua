function FreshSoD_SaveDBData(key, value)
  local characterGUID = UnitGUID('player')

  if not FRESH_SOD_DB then
    FRESH_SOD_DB = {}
  end

  if not FRESH_SOD_DB.characterSettings then
    FRESH_SOD_DB.characterSettings = {}
  end

  if not FRESH_SOD_DB.characterSettings[characterGUID] then
    FRESH_SOD_DB.characterSettings[characterGUID] = {}
  end

  FRESH_SOD_DB.characterSettings[characterGUID][key] = value

  if FRESH_SOD_GLOBAL_SETTINGS then
    FRESH_SOD_GLOBAL_SETTINGS[key] = value
  end
end
