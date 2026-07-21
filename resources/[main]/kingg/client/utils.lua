CreateThread(function()
	while true do
		Wait(1000)
		SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
		local ped = PlayerPedId()
		SetForcePedFootstepsTracks(ped, false)
		SetForceVehicleTrails(false)
		SetPedAudioFootstepLoud(ped, false)
		SetPlayerCanUseCover(PlayerId(), false)
	end
end)
