function FreshSoD_GetDeathTaxOwedCopper()
  return FreshSoD_GetDBValue('deathTaxOwedCopper') or 0
end

function FreshSoD_AddDeathTaxOwedCopper(amount)
  if type(amount) ~= 'number' or amount < 0 then
    return FreshSoD_GetDeathTaxOwedCopper()
  end

  local owed = FreshSoD_GetDeathTaxOwedCopper() + amount
  FreshSoD_SaveDBData('deathTaxOwedCopper', owed)
  return owed
end
