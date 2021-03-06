local PropertyBlips = {}
local CurrentHouse = nil
local Rob = nil
local AP = {}
local OwnedProperties = {}
local OwnedBlips = {}

RegisterCommand('house', function(source, args, raw)
	local src = source
	local action = tostring(args[1])
	GetOwnedProperties()
	Citizen.Wait(500)
	local ped = PlayerPedId()
	local Coords = GetEntityCoords(ped)
	if action == 'unlock' or action == 'lock' then
		for k,v in pairs(OwnedProperties) do
			local distance = GetDistanceBetweenCoords(Coords, Config.Properties[v.key].Entrance)
			if distance < 3 then
				TriggerServerEvent('FD_Properties:SetDoorStatus', v.key, action)
			end
			local distance = GetDistanceBetweenCoords(Coords, Config.Properties[v.key].Exit)
			if distance < 3 then
				TriggerServerEvent('FD_Properties:SetDoorStatus', v.key, action)
			end
		end
	elseif action == 'givekeys' then
		local Target, TargetDistance = GetClosestPlayer()
		local TargetPlayer = GetPlayerServerId(Target)
		for k,v in pairs(OwnedProperties) do
			local distance = GetDistanceBetweenCoords(Coords, Config.Properties[v.key].Entrance)
			if distance < 3 then
				if TargetDistance <= 3 then
					TriggerServerEvent('FD_Properties:GiveKeys', v.key, TargetPlayer)
				end
			end
		end
	elseif action == 'changelocks' then
		for k,v in pairs(OwnedProperties) do
			local distance = GetDistanceBetweenCoords(Coords, Config.Properties[v.key].Entrance)
			if distance < 3 then
					TriggerServerEvent('FD_Properties:ChangeLocks', v.key)
			end
	 	end
	elseif action == 'mortgage' then
		if args[2] == nil then
			GetMortgage()
		else
			PayMortgage(args[2])
		end
	elseif action == 'update' then
		--Notification that houses updated
		DrawOwnedBlips()
	elseif action == 'setstash' then
			if CurrentHouse ~= nil then
				TriggerServerEvent('FD_Properties:SetStash', CurrentHouse, Coords)
			end
	elseif action == 'sell' then
		local amount = tonumber(args[2])
		for k,v in pairs(OwnedProperties) do
			local distance = GetDistanceBetweenCoords(Coords, Config.Properties[v.key].Entrance)
			if distance < 3 then
				TriggerServerEvent('FD_Properties:SellHouse', v.key, amount)
			end
	 	end
	 elseif action == 'buy' then
	 	for k,v in pairs(OwnedProperties) do
			local distance = GetDistanceBetweenCoords(Coords, Config.Properties[v.key].Entrance)
			if distance < 3 then
				DRP.NetCallbacks.Trigger('FD_Properties:BuyCost', function(result)
					if result[k] ~= nil then
						TriggerEvent("DRP_Core:Info", "Housing", "House is listed for : $ "..result[k].amount..'. "/housing buyconfirm" to purchase this house.', 5000, true, "leftCenter")
					else
						TriggerEvent("DRP_Core:Error", "Housing", "House is not for sale.", 2500, true, "leftCenter")
					end
				end)
			end
	 	end
	 elseif action == 'buyconfirm' then
		for k,v in pairs(OwnedProperties) do
			local distance = GetDistanceBetweenCoords(Coords, Config.Properties[v.key].Entrance)
			if distance < 3 then
				TriggerServerEvent('FD_Properties:BuyHouse', v.key)
			end
	 	end
	 elseif action == 'rob' then
	 	print('Rob')
	 	local CurrentHouse = CurrentHouse(Coords)
	 	print(CurrentHouse)
	 	RobHouse(CurrentHouse)

	 elseif action == 'purchase' then
	 	if args[2] == 'info' then
	 		local CurrentHouse = CurrentHouse(Coords)
	 		local cost = Config.Properties[CurrentHouse].Cost
			local down = math.ceil(cost*0.05)
			local weekly = math.ceil((cost-down)/12)
	 		drawNotification('Cost: '..cost)
	 		drawNotification('Down Payment: $'..down..'. Weekly: $'..weekly..' for 12 weeks.')

	 	elseif args[2] == 'view' then
	 		CurrentHouse = CurrentHouse(Coords)
	 		ViewHouse(CurrentHouse)

	 	elseif args[2] == 'buy' then
	 		local CurrentHouse = CurrentHouse(Coords)
	 		TriggerServerEvent('FD_Properties:PurchaseHouse', CurrentHouse, 'Buy')
	 		CurrentHouse = nil
	 		Citizen.Wait(1000)
			TogglePropertyBlips()
			Citizen.Wait(1000)
			GetOwnedProperties()

	 	elseif args[2] == 'mortgage' then
	 		local CurrentHouse = CurrentHouse(Coords)
	 		TriggerServerEvent('FD_Properties:PurchaseHouse', CurrentHouse, 'Mortgage')
	 		CurrentHouse = nil
	 		Citizen.Wait(1000)
			TogglePropertyBlips()
			Citizen.Wait(1000)
			GetOwnedProperties()

	 	end
	end

end, false)

RegisterNetEvent('FD_Properties:SendProperties')
AddEventHandler('FD_Properties:SendProperties', function()
	Citizen.Wait(2000)
	GetOwnedProperties()
	Citizen.Wait(2000)
	DrawOwnedBlips()
end)

function TogglePropertyBlips()
	if tablelength(PropertyBlips) == 0 then
		for k,v in pairs(AP) do
			local blip = AddBlipForCoord(v.Entrance)
			PropertyBlips[blip] = {v.Entrance, k}
		end
		for k,v in pairs(PropertyBlips) do
			local blip = k
			SetBlipSprite(blip, 40)
			SetBlipDisplay(blip, 4)
			SetBlipScale(blip, 1.0)
			SetBlipColour(blip, 2)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName('House For Sale')
			EndTextCommandSetBlipName(blip)
		end
	else
		for k,v in pairs(PropertyBlips) do
			RemoveBlip(k)
		end
		PropertyBlips = {}
		CurrentHouse = nil
	end
end
local CharID = nil
function DrawOwnedBlips()
	GetOwnedProperties()
	Citizen.Wait(2000)
	if tablelength(OwnedBlips) == 0 then
			DRP.NetCallbacks.Trigger('FD_Properties:GetCharId', function(result)
				CharID = result
			end)
			Citizen.Wait(1000)
		for k,v in pairs(OwnedProperties) do
			if v.char_id == CharID then
				local blip = AddBlipForCoord(Config.Properties[v.key].Entrance)
				OwnedBlips[blip] = {v.key}
			end
		end
		for k,v in pairs(OwnedBlips) do
			local blip = k
			SetBlipSprite(blip, 40)
			SetBlipDisplay(blip, 4)
			SetBlipScale(blip, 0.75)
			SetBlipColour(blip, 26)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName('Owned House')
			EndTextCommandSetBlipName(blip)
		end
	else
		for k,v in pairs(OwnedBlips) do
			RemoveBlip(k)
		end
		OwnedBlips = {}
		CurrentHouse = nil
	end

end

function ViewHouse()
	local ped = PlayerPedId()
	SetEntityCoords(ped, AP[CurrentHouse].Exit)
end

function LeaveHouse()
	local ped = PlayerPedId()
	SetEntityCoords(ped, Config.Properties[CurrentHouse].Entrance)
	CurrentHouse = nil
end

function EnterHouse(Coords)
	local ped = PlayerPedId()
	SetEntityCoords(ped, Coords)
end

function ExitHouse(Coords)
	local ped = PlayerPedId()
	SetEntityCoords(ped, Coords)
	CurrentHouse = nil
end

function GetOwnedProperties()
	DRP.NetCallbacks.Trigger('FD_Properties:GetOwned', function(result)
		OwnedProperties = result
	end)
end

function GetMortgage()
	DRP.NetCallbacks.Trigger('FD_Properties:GetMortgage', function(result)
		for k,v in pairs(result) do
			if v.due == 'True' then
				drawNotification('House ID: '..v.key..' Due: '..v.mortgage_payments..' Payments of: '..v.mortgage_amount..'. Currently due: ~r~'..v.due)
			else
				drawNotification('House ID: '..v.key..' Due: '..v.mortgage_payments..' Payments of: '..v.mortgage_amount..'. Currently due: ~g~'..v.due)
			end
		end
		
	end)	
end

function PayMortgage(key)
	TriggerServerEvent('FD_Properties:PayMortgage', key)
end

function SellHouse(A)
	local amount = A
end

function CurrentHouse(Coords)
	for k,v in pairs(Config.Properties) do
	 	distance = GetDistanceBetweenCoords(Coords, v.Entrance)
	 	if distance <= 2 then
	 		print(distance)
	 		return k
	 	end
	 end
end

function RobHouse(CH)
	local CurrentHouse = CH
	DRP.NetCallbacks.Trigger('FD_Properties:DoorStatus', function(result)
		if result ~= nil then
			local HasKeys = false
			for k,v in pairs(result) do
				if CurrentHouse == result.key then
					HasKeys = true
				end
			end
			if not HasKeys then
				BreakIntoHouse(CurrentHouse)
			else
				--Can't rob, has keys
			end
		end
	end)
end

function BreakIntoHouse(Key)
	local ped = PlayerPedId()
	local key = Key
	TaskStartScenarioInPlace(ped, "PROP_HUMAN_BUM_BIN", 0, true)
	Citizen.Wait(1000)
	ClearPedTasks(ped)
	local Coords = GetEntityCoords(ped)
	local distance = GetDistanceBetweenCoords(Coords, Config.Properties[key].Entrance)
	if distance <= 2 then
		SetEntityCoords(ped, Config.Properties[key].Exit)
		CurrentHouse = key
	end
end
--[[
Citizen.CreateThread(function()
	WarMenu.CreateMenu('view_house', 'House Menu')
	WarMenu.SetSubTitle('view_house', '')
	WarMenu.CreateSubMenu('buy_options', 'view_house', 'Buy House')
	WarMenu.CreateSubMenu('purchase_house','view_house', 'Purchase House')
	WarMenu.CreateSubMenu('mortgage_house','view_house', 'Mortgage House')

	while true do
		if WarMenu.IsMenuOpened('view_house') then
			WarMenu.SetSubTitle('view_house', '$'..Config.Properties[CurrentHouse].Cost)
			if WarMenu.Button('View Interior') then
				--TP player into house
				ViewHouse()
				WarMenu.CloseMenu()
			end
			if WarMenu.MenuButton('Buy House', 'buy_options') then

			end
			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('buy_options') then
			if WarMenu.MenuButton('Purchase House', 'purchase_house') then

			end
			if WarMenu.MenuButton('Mortgage House', 'mortgage_house') then
				local cost = Config.Properties[CurrentHouse].Cost
				local down = math.ceil(cost*0.05)
				local weekly = math.ceil((cost-down)/12)
				WarMenu.SetSubTitle('mortgage_house', 'Down: $'..down..', Weekly: $'..weekly)
			end
			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('purchase_house') then
			if WarMenu.Button('Yes') then
				--Buy House
				TriggerServerEvent('FD_Properties:PurchaseHouse', CurrentHouse, 'Buy')
				WarMenu.CloseMenu()
				CurrentHouse = nil
				TogglePropertyBlips()
				Citizen.Wait(1000)
				GetOwnedProperties()
			elseif WarMenu.MenuButton('No', 'view_house') then

			end
			WarMenu.Display()
		elseif WarMenu.IsMenuOpened('mortgage_house') then
			if WarMenu.Button('Yes') then
				--Mortgage House
				TriggerServerEvent('FD_Properties:PurchaseHouse', CurrentHouse, 'Mortgage')
				WarMenu.CloseMenu()
				CurrentHouse = nil
				TogglePropertyBlips()
				Citizen.Wait(1000)
				GetOwnedProperties()
			elseif WarMenu.MenuButton('No', 'view_house') then

			end
			WarMenu.Display()
		end
		Citizen.Wait(0)
	end
end)
]]

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local letSleep = true

        for k,v in pairs(PropertyBlips) do
            local distance = GetDistanceBetweenCoords(playerCoords, v[1], true)
            if distance < Config.Distance then
                letSleep = false
                DrawMarker(20, v[1].x, v[1].y, v[1].z-0.40, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 200, false, true, 2, false, nil, nil, false)
                if distance < 3 then
                	Draw3DText(v[1].x, v[1].y, v[1].z, 'Use /house pruchase')
                	--[[
                    Draw3DText(v[1].x, v[1].y, v[1].z, '~g~[E]~w~ View House')
                    if IsControlJustReleased(0, 38) then
                    	if not IsPedInAnyVehicle(ped, false) then
                        	WarMenu.OpenMenu('view_house')
                        	CurrentHouse = v[2]
                   		end
                	end
                else
                	WarMenu.CloseMenu()
                	]]
                end
            end
        end

        if CurrentHouse ~= nil then
        	if Config.Properties[CurrentHouse] ~= nil then
	        	local v = Config.Properties[CurrentHouse]
	            local distance = GetDistanceBetweenCoords(playerCoords, v.Exit, true)
	            if distance < Config.Distance then
	                letSleep = false
	                DrawMarker(20, v.Exit.x, v.Exit.y, v.Exit.z-0.40, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 200, false, true, 2, false, nil, nil, false)
	                if distance < 3 then
	                    Draw3DText(v.Exit.x, v.Exit.y, v.Exit.z, '~g~[E]~w~ Leave House')
	                    if IsControlJustReleased(0, 38) then
	                        LeaveHouse()
	                	end
	                end
	            end
	        end
    	end
        if letSleep then
            Citizen.Wait(500)
        end
    end
end)

--[[
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local letSleep = true
        if CurrentHouse ~= nil then
        	if AP[CurrentHouse] ~= nil then
	        	local v = AP[CurrentHouse]
	            local distance = GetDistanceBetweenCoords(playerCoords, v.Exit, true)
	            if distance < Config.Distance then
	                letSleep = false
	                DrawMarker(20, v.Exit.x, v.Exit.y, v.Exit.z-0.40, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 200, false, true, 2, false, nil, nil, false)
	                if distance < 3 then
	                    Draw3DText(v.Exit.x, v.Exit.y, v.Exit.z, '~g~[E]~w~ Leave House')
	                    if IsControlJustReleased(0, 38) then
	                        LeaveHouse()
	                	end
	                end
	            end
	        end
    	end
        if letSleep then
            Citizen.Wait(5000)
        end
    end
end)
]]

--local status = {}
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local letSleep = true
        for k,v in pairs(OwnedProperties) do
        	local Coords = Config.Properties[v.key].Entrance
            local distance = GetDistanceBetweenCoords(playerCoords, Coords, true)
            if distance < Config.Distance then
                letSleep = false
                DrawMarker(20, Coords.x, Coords.y, Coords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 94, 156, 255, 130, false, true, 2, false, nil, nil, false)
                if distance < 3 then
                    if IsControlJustReleased(0, 38) then
                    	DRP.NetCallbacks.Trigger('FD_Properties:DoorStatus', function(result)
                    		Citizen.Wait(500)
                    		if result ~= nil then
                    			local status = tonumber(result.owned[k].status)
	                    		if status == 0 then
	                    			if not IsPedInAnyVehicle(ped, false) then
	                    				CurrentHouse = v.key
	                    				EnterHouse(Config.Properties[v.key].Exit)
	                    			end
	                    		else
	                    			if result.player ~= nil then
	                    				local locked = true
		                    			for k2,v2 in pairs(result.player) do
				                			if v.key == v2.key then
				                				if not IsPedInAnyVehicle(ped, false) then
				                					local locked = false
				                					CurrentHouse = v.key
				                    				EnterHouse(Config.Properties[v.key].Exit)
				                    			end
				                    		end
				                    	end
				                    	if locked then
				                    		TriggerEvent("DRP_Core:Info", "Housing", "Door is locked.", 2500, true, "leftCenter")
				                    	end
			                    	end
		                    	end
                    		end
                    	end)
                	end
                end
            end
            local Coords = Config.Properties[v.key].Exit
            local distance = GetDistanceBetweenCoords(playerCoords, Coords, true)
            if distance <= 3 then
            	letSleep = false
            	if IsControlJustReleased(0, 38) then
            		CurrentHouse = nil
                    ExitHouse(Config.Properties[v.key].Entrance)
            	end
            end
            --print(v.stash)
            if v.stash ~= nil then
            	--local Coords = json.decode(v.stash)
            	--local x, y, z = Coords.x, Coords.y, Coords.z
            	local distance = GetDistanceBetweenCoords(playerCoords, v.stash, true)
            	if distance <= 5 then
            		letSleep = false
            		if distance < 2 then
            			if IsControlJustReleased(0, 38) then
            				DRP.NetCallbacks.Trigger('FD_Properties:CanStash', function(result)
								if result ~= nil then
									for k2,v2 in pairs(result) do
										if v.key == v2.key then
											print('IT WORKED')
										end
									end
								end
							end)
            			end
            		end
            	end
            end
        end
        if letSleep then
            Citizen.Wait(1500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local letSleep = true
        for k,v in pairs(Config.Offices) do
            local distance = GetDistanceBetweenCoords(playerCoords, v.Coords, true)
            if distance < Config.Distance then
                letSleep = false
                DrawMarker(20, v.Coords.x, v.Coords.y, v.Coords.z-0.40, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 200, false, true, 2, false, nil, nil, false)
                if distance < 3 then
                	if tablelength(PropertyBlips) == 0 then
	                    Draw3DText(v.Coords.x, v.Coords.y, v.Coords.z, '~g~[E]~w~ Show Houses For Sale')
	                    if IsControlJustReleased(0, 38) then
	                    	DRP.NetCallbacks.Trigger("FD_Properties:GetAvailableHouses", function(result)
	                    		AP = result
	                    		Citizen.Wait(500)
	                    		TogglePropertyBlips()
	                    	end)
                    	end
                    else
                    	Draw3DText(v.Coords.x, v.Coords.y, v.Coords.z, '~g~[E]~w~ Hide Houses For Sale')
	                    if IsControlJustReleased(0, 38) then
	                        TogglePropertyBlips()
	                    end
                    end
                end
            end
        end
        if letSleep then
            Citizen.Wait(1500)
        end
    end
end)

Citizen.CreateThread(function()
	for k,v in pairs(Config.Offices) do
		local blip = AddBlipForCoord(v.Coords)
		SetBlipSprite(blip, 374)
		SetBlipDisplay(blip, 4)
		SetBlipScale(blip, 1.0)
		SetBlipColour(blip, 47)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName('Real Estate Office')
		EndTextCommandSetBlipName(blip)
	end
	GetOwnedProperties()
	Citizen.Wait(60000)
	DrawOwnedBlips()
end)


function GetClosestPlayer()
    local players = GetPlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply)
    
    for index,value in ipairs(players) do
        local target = GetPlayerPed(value)
        if(target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value))
            local distance = GetDistanceBetweenCoords(targetCoords["x"], targetCoords["y"], targetCoords["z"], plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
            if(closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end
---------------------------------------------------------------------------
function GetPlayers()
    return GetActivePlayers()
end

--Draw text above markers
function Draw3DText(x, y, z, text)
    -- Check if coords are visible and get 2D screen coords
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        -- Calculate text scale to use
        local dist = GetDistanceBetweenCoords(GetGameplayCamCoords(), x, y, z, 1)
        local scale = 1.8*(1/dist)*(1/GetGameplayCamFov())*100

        -- Draw text on screen
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropShadow(0, 0, 0, 0,255)
        SetTextDropShadow()
        SetTextEdge(4, 0, 0, 0, 255)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function Draw2DText(text, x, y)
    SetTextFont(4)
    SetTextScale(0.45, 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()

    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function drawNotification(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do 
        count = count + 1 
    end
    return count
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end