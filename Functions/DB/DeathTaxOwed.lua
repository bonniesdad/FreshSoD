function FreshSoD_GetDeathTaxOwedCopper()
  return FreshSoD_GetDBValue('deathTaxOwedCopper') or 0
end

function FreshSoD_GetDeathTaxTotalAccumulatedCopper()
  return FreshSoD_GetDBValue('deathTaxTotalAccumulatedCopper') or 0
end

function FreshSoD_AddDeathTaxOwedCopper(amount)
  amount = math.max(tonumber(amount) or 0, 0)
  local owed = FreshSoD_GetDeathTaxOwedCopper() + amount
  local total = FreshSoD_GetDeathTaxTotalAccumulatedCopper() + amount
  FreshSoD_SaveDBData('deathTaxOwedCopper', owed)
  FreshSoD_SaveDBData('deathTaxTotalAccumulatedCopper', total)
  return owed
end

function FreshSoD_ClearDeathTaxOwedCopper()
  FreshSoD_SaveDBData('deathTaxOwedCopper', 0)
end
