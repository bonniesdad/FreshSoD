FreshSoD = CreateFrame('Frame')

FreshSoD:RegisterEvent('PLAYER_LOGIN')

FreshSoD:SetScript('OnEvent', function(self, event, ...)
  if event == 'PLAYER_LOGIN' then
    FreshSoD_InitializeDBData()
    FreshSoD_MinimapButton_Initialize()
  end
end)
