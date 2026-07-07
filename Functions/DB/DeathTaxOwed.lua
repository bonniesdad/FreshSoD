function FreshSoD_GetDeathTaxOwedCopper()
  return FreshSoD_GetDBValue('deathTaxOwedCopperV2') or 0
end

function FreshSoD_GetDeathTaxTotalAccumulatedCopper()
  return FreshSoD_GetDBValue('deathTaxTotalAccumulatedCopperV2') or 0
end

function FreshSoD_AddDeathTaxOwedCopper(amount)
  amount = math.max(tonumber(amount) or 0, 0)
  local owed = FreshSoD_GetDeathTaxOwedCopper() + amount
  local total = FreshSoD_GetDeathTaxTotalAccumulatedCopper() + amount
  FreshSoD_SaveDBData('deathTaxOwedCopperV2', owed)
  FreshSoD_SaveDBData('deathTaxTotalAccumulatedCopperV2', total)
  return owed
end

function FreshSoD_ClearDeathTaxOwedCopper()
  FreshSoD_SaveDBData('deathTaxOwedCopperV2', 0)
end
