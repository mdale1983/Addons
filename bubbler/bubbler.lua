_addon.name = 'Bubbler'
_addon.author = 'Actually Keevon'
_addon.version = '4.2.0.69'
_addon.command = 'bub'

require 'strings'
require 'actions'
packets = require('packets')
res = require('resources')

windower.register_event('load', function()
	tagged = {}
	movementarray = {}
	touched = {}
	tagged = {}
	watched = "Enuri"
	entrusttarget = "Enuri"
	geoparam = 818		--default frailty
	indiparam = 779		--default fury
	entrustparam = 772	--default STR
	debugmode = false
	enabled = true
	blaze = false
	ecliptic = false
	dematerialize = false
	lifecycle = false
	freebuff = false
	castdelay = 0
	touchactor = 0
	touchcount = 0
	touchmax = 0
end)

windower.register_event('addon command', function(command, ...)
	local args = T{...}
	if command:lower() == 'on' then
		enabled = true
		return
	elseif command:lower() == 'off'  then
		enabled = false
		return
	elseif command:lower() == 'debug' then
		debugmode = not debugmode
		print('Debug: '..tostring(debugmode))
	elseif command:lower() == 'blaze' or command:lower() == 'bog' then
		blaze = not blaze
		print('Blaze of Glory: '..tostring(blaze))
	elseif command:lower() == 'ecliptic' or command:lower() == 'ea' then
		ecliptic = not ecliptic
		print('Ecliptic Attrition: '..tostring(ecliptic))
	elseif command:lower() == 'dematerialize' or command:lower() == 'demat' then
		dematerialize = not dematerialize
		print('Dematerialize: '..tostring(dematerialize))
	elseif command:lower() == 'lifecycle' or command:lower() == 'lc' then
		lifecycle = not lifecycle
		print('Life Cycle: '..tostring(lifecycle))
	elseif command:lower() == 'freebuff' then
		freebuff = not freebuff
		print('FreeBuff: '..tostring(freebuff))
	elseif command:lower() == 'buffs' then
		if args[1] == 'off' then
			blaze = false
			ecliptic = false
			dematerialize = false
			lifecycle = false
			print('All buffs disabled')
		elseif args[1] == 'on' then
			blaze = true
			ecliptic = true
			dematerialize = true
			lifecycle = true
			print('All buffs enabled')
		end			
	elseif command:lower() == 'watch' then
		for i,v in pairs(windower.ffxi.get_mob_array()) do
			if v.name == tostring(args[1]) then
				print('Watching: '..args[1])
				watched = tostring(args[1])	
				return
			end
		end
		print('Couldn\'t find '..args[1])
		return
	elseif command:lower() == 'geo' then
		for k,v in pairs(res.spells) do
			if v.type == 'Geomancy' then
				local geoname = v.en:lower()
				if geoname:contains(tostring(args[1]:lower())) and v.en:contains('Geo') then
					print("Geo set: "..v.en)
					geoparam = v.id
					return
				end
			end
		end
	elseif command:lower() == 'indi' then
		for k,v in pairs(res.spells) do
			if v.type == 'Geomancy' then
				local geoname = v.en:lower()
				if geoname:contains(tostring(args[1]:lower())) and v.en:contains('Indi') then
					print("Indi set: "..v.en)
					indiparam = v.id
					return
				end
			end
		end
	elseif command:lower() == 'entrust' then
		for k,v in pairs(res.spells) do
			if v.type == 'Geomancy' then
				local geoname = v.en:lower()
				if geoname:contains(tostring(args[1]:lower())) and v.en:contains('Indi') then
					print("Entrust set: "..v.en)
					entrustparam = v.id
					return
				end
			end
		end
		for i,v in pairs(windower.ffxi.get_mob_array()) do
			if v.name == tostring(args[1]) and v.in_party then
				print('Entrust Target: '..args[1])
				entrusttarget = tostring(args[1])	
				return
			end
		end
	end
end)

function bubalive()
	if windower.ffxi.get_mob_by_target("pet") ~= nil then
		return true
	else
		return false
	end
end

function checkbubdistance(targetid)
	local bub = windower.ffxi.get_mob_by_target("pet")
	local target = windower.ffxi.get_mob_by_id(targetid)
	
	if bub == nil or target == nil then
		return false
	end
	
	local xdiff = bub.x - target.x
	local ydiff = bub.y - target.y
	
	if math.sqrt(xdiff^2 + ydiff^2) < (5.75 + target.model_size) and target.is_npc and not target.in_alliance and target.hpp ~= 0 and target.id ~= bub.id and target.name ~= "Luopan" and target.valid_target and target.status == 1 then
		return true
	else
		return false
	end
end

function validbub()
	local mobarray = windower.ffxi.get_mob_array()
	
	for i,v in pairs(mobarray) do
		if checkbubdistance(v.id) then
			return
		end
	end

	if bubalive() then
		windower.send_command('ja \"Full Circle\" <me>')
		castdelay = 5
	end
	
	return
end

function autogeo()
	local mobarray = windower.ffxi.get_mob_array()
	bubtarget = T{}
	watchedindex = 0
	
	for i,v in pairs(mobarray) do
		if v.name == watched and v.target_index ~= 0 then
			bubtarget = windower.ffxi.get_mob_by_index(v.target_index)
		end
	end
	
	if not bubalive() and geoparam ~= 0 then
		if res.spells[geoparam].targets == S{'Enemy'} then
			if bubtarget.id ~= nil and bubtarget.is_npc and bubtarget.valid_target and bubtarget.status == 1 and
			((windower.ffxi.get_mob_by_id(bubtarget.claim_id) ~= nil and windower.ffxi.get_mob_by_id(bubtarget.claim_id).in_alliance) or tagged[bubtarget.id]) and bubtarget.distance:sqrt() < 21 and not movementarray[bubtarget.id]["moving"] and not movementarray[windower.ffxi.get_player().id]["moving"] then
				if blaze and not hasbuff(569) and windower.ffxi.get_ability_recasts()[247] == 0 then
					windower.send_command('ja \"Blaze of Glory\" <me>')
					castdelay = 3
				elseif windower.ffxi.get_player().vitals.mp > res.spells[geoparam].mp_cost and cancast() then
					windower.send_command('gs equip midcast.Geomancy')
					local packet = packets.new('outgoing', 0x01A)
					packet["Target"]=bubtarget.id
					packet["Target Index"]=bubtarget.index
					packet["Category"]=3
					packet["Param"]=geoparam
					packets.inject(packet)
					castdelay = 3
				end
			end
		elseif res.spells[geoparam].targets:contains('Party') then
			if windower.ffxi.get_mob_by_name(watched) ~= nil and windower.ffxi.get_mob_by_name(watched).in_party and windower.ffxi.get_mob_by_name(watched).distance:sqrt() < 21 and bubtarget ~= nil then
				if blaze and not hasbuff(569) and windower.ffxi.get_ability_recasts()[247] == 0 then
					windower.send_command('ja \"Blaze of Glory\" <me>')
					castdelay = 3
				elseif windower.ffxi.get_player().vitals.mp > res.spells[geoparam].mp_cost and cancast() then
					windower.send_command('ma \"'..res.spells[geoparam].en..'\" '..watched)
					castdelay = 3
				end
			end
		end
	end
end

function autoindi()
	local player = windower.ffxi.get_player()

	if not hasbuff(612) and not hasbuff(584) and cancast() and windower.ffxi.get_player().vitals.mp > res.spells[indiparam].mp_cost and not movementarray[player.id]["moving"] then
		windower.send_command('ma '..res.spells[indiparam].en..' <me>')
		castdelay = 3
	end
end

function autoentrust()
	local player = windower.ffxi.get_player()
	local mobarray = windower.ffxi.get_mob_array()
	local entrusted = T{}
	
	for i,v in pairs(mobarray) do
		if v.name == entrusttarget and v.in_party then
			entrusted = windower.ffxi.get_mob_by_id(v.id)
		end
	end
	
	if not hasbuff(584) and cancast() and windower.ffxi.get_ability_recasts()[93] == 0 and windower.ffxi.get_player().vitals.mp > res.spells[entrustparam].mp_cost and entrusted.distance ~= nil and entrusted.distance:sqrt() < 21 and entrusted.in_party and entrusted.hpp > 0 and (entrusted.status == 1 or entrustparam == 770) then
		windower.send_command('ja Entrust <me>')
		castdelay = 3
	end	
	
	if hasbuff(612) and hasbuff(584) and cancast() and entrusted.distance:sqrt() < 21 and entrusted.in_party and entrusted.hpp > 0 and not movementarray[player.id]["moving"] then
		windower.send_command('ma '..res.spells[entrustparam].en..' '..entrusttarget)
		castdelay = 3
	end
end

function postbuffs()
	local player = windower.ffxi.get_player()
	
	if windower.ffxi.get_mob_by_target("pet") ~= nil and (buffedbubble == windower.ffxi.get_mob_by_target("pet").id or freebuff) then
		if windower.ffxi.get_ability_recasts()[244] == 0 and ecliptic then 
			windower.send_command('ja "Ecliptic Attrition" <me>')
			castdelay = 3
		elseif windower.ffxi.get_ability_recasts()[248] == 0 and dematerialize then 
			windower.send_command('ja "Dematerialize" <me>')
			castdelay = 3
		elseif windower.ffxi.get_ability_recasts()[246] == 0 and windower.ffxi.get_mob_by_target("pet").hpp <= 65 and lifecycle then 
			windower.send_command('ja "Life Cycle" <me>')
			castdelay = 3
		end
	end
		
end

function movementcheck()
	local mobarray = windower.ffxi.get_mob_array()
	
	for i,v in pairs(mobarray) do
		if mobarray[i].hpp ~= 0 and mobarray[i].valid_target then
			if movementarray[mobarray[i].id] == nil and mobarray[i].id ~= 0 then
				movementarray[mobarray[i].id] = {}
				movementarray[mobarray[i].id]["x1"] = mobarray[i].x
				movementarray[mobarray[i].id]["y1"] = mobarray[i].y
				movementarray[mobarray[i].id]["x2"] = 0
				movementarray[mobarray[i].id]["y2"] = 0
				movementarray[mobarray[i].id]["status"] = mobarray[i].status
				movementarray[mobarray[i].id]["moving"] = true
				movementarray[mobarray[i].id]["timer"] = 2
			end
		end
	end
	
	for i,v in pairs(movementarray) do
		if windower.ffxi.get_mob_by_id(i) ~= nil and windower.ffxi.get_mob_by_id(i).x ~= nil then
			movementarray[i]["x1"] = windower.ffxi.get_mob_by_id(i).x
			movementarray[i]["y1"] = windower.ffxi.get_mob_by_id(i).y
		end
	end
	
	for i,v in pairs(movementarray) do
		if (math.abs(movementarray[i]["x1"] - movementarray[i]["x2"]) > 0.5 or math.abs(movementarray[i]["y1"] - movementarray[i]["y2"]) > 0.5) or (windower.ffxi.get_mob_by_id(i) ~= nil and movementarray[i]["status"] ~= windower.ffxi.get_mob_by_id(i).status) then
			movementarray[i]["moving"] = true
			movementarray[i]["timer"] = 2
		elseif movementarray[i]["timer"] > 0 then
			movementarray[i]["timer"] = movementarray[i]["timer"] - 1
		elseif movementarray[i]["timer"] <= 0 then
			movementarray[i]["moving"] = false
		end
	end
	
	for i,v in pairs(movementarray) do
		movementarray[i]["x2"] = movementarray[i]["x1"]
		movementarray[i]["y2"] = movementarray[i]["y1"]
		if windower.ffxi.get_mob_by_id(i) ~= nil then
			movementarray[i]["status"] = windower.ffxi.get_mob_by_id(i).status
		else
			movementarray[i]["status"] = 0
		end
	end
	
	
end

windower.register_event('action',function (act)
	if windower.ffxi.get_mob_by_id(act.actor_id).in_alliance and act.category < 7 then
		for i,v in pairs(act.targets) do
			if windower.ffxi.get_mob_by_id(act.targets[i].id).is_npc then
				if touched[act.actor_id] == nil then
					touched[act.actor_id] = {}
					if debugmode then
						print("Added actor by touch: "..act.actor_id)
					end
				end
				if touched[act.actor_id][act.targets[i].id] == nil then
					touched[act.actor_id][act.targets[i].id] = true
					if debugmode then
						print("Added target by touch: "..act.targets[i].id)
					end
				end
						
				if act.actor_id == windower.ffxi.get_player().id then
					for x,y in pairs(act.targets) do
						tagged[act.targets[x].id] = true
						if debugmode then
							print("Tagged: "..act.targets[x].id)
						end
					end
				end
			end
		end
	end
	
	if act.actor_id == windower.ffxi.get_player().id and act.category < 7 then
		for i,v in pairs(act.targets) do
			if touched[act.targets[i].id] ~= nil then
				for x,y in pairs(touched[act.targets[i].id]) do
					tagged[x] = true
					if debugmode then
						print("Tagged: "..x)
					end
				end
			end
		end
	end
	
end)

function checkclaims()
	local mobarray = windower.ffxi.get_mob_array()
	
	for i,v in pairs(mobarray) do
		if windower.ffxi.get_mob_by_id(v.claim_id) ~= nil and windower.ffxi.get_mob_by_id(v.claim_id).in_alliance and windower.ffxi.get_mob_by_id(v.claim_id) ~= windower.ffxi.get_player().id and v.status == 1 and v.hpp > 0 then
			if touched[v.claim_id] == nil then
				if debugmode then
					print("Added actor by claim: "..v.claim_id)
				end
				touched[v.claim_id] = {}
			end
			if touched[v.claim_id][v.id] == nil then
				if debugmode then
					print("Added target by claim: "..v.id)
				end
				touched[v.claim_id][v.id] = true
			end
		end
	end
end

function cleanarrays()
	for i,v in pairs(touched) do
		if windower.ffxi.get_mob_by_id(i) == nil or not windower.ffxi.get_mob_by_id(i).in_alliance then
			touched[i] = nil
			if debugmode then
				print("Removed actor: "..i)
			end
		end
		for x,y in pairs(touched[i]) do
			if windower.ffxi.get_mob_by_id(x) == nil or windower.ffxi.get_mob_by_id(x).hpp == 0 then
				touched[i][x] = nil
				if debugmode then
					print("Removed target: "..x.." from actor: "..i)
				end
			end
		end
	end
	
	for i,v in pairs(tagged) do
		if windower.ffxi.get_mob_by_id(i) == nil or windower.ffxi.get_mob_by_id(i).hpp == 0 then
			tagged[i] = nil
			if debugmode then
				print("Removed tag: "..i)
			end
		end
	end
	
	for i,v in pairs(movementarray) do
		if windower.ffxi.get_mob_by_id(i) == nil or windower.ffxi.get_mob_by_id(i).hpp == 0 or windower.ffxi.get_mob_by_id(i).x == nil then
			movementarray[i] = nil
			if debugmode then
				print("Removed movement: "..i)
			end
		end
	end
end

function selecttag()

	touchactor = 0
	touchcount = 0
	touchmax = 0
	
	for i,v in pairs(touched) do
		if touchactor == 0 then
			touchactor = i
		end
		for x,y in pairs(touched[i]) do
			if tagged[x] ~= true then
				touchcount = (touchcount+1)
			end
		end
		if touchcount > touchmax then
			touchactor = i
			touchmax = touchcount
			touchcount = 0
		end
	end
	--print("Best actor: "..touchactor.." with "..touchmax.." touches")

end

function tag()
	if windower.ffxi.get_mob_by_id(touchactor) ~= nil and touchmax ~= 0 and bubalive() and cancast() and windower.ffxi.get_mob_by_id(touchactor).distance:sqrt() < 21 then
		windower.send_command('ma \"Cure\" '..windower.ffxi.get_mob_by_id(touchactor).name)
		castdelay = 3
	end
end

windower.register_event('outgoing chunk',function(id,original,modified,is_injected,is_blocked)
	if id == 0x015 and enabled and (windower.ffxi.get_player().status == 0 or windower.ffxi.get_player().status == 1) then
		
		if castdelay > 0 then
			castdelay = castdelay - 1
		end
		
		movementcheck()
		checkclaims()
		cleanarrays()
		selecttag()
		if castdelay == 0 then	
			validbub()
			autoindi()
			if hasbuff(612) then
				autogeo()
			end
			autoentrust()
			postbuffs()
			tag()
		end
	end
end)

windower.register_event('action',function (act)
	local player = windower.ffxi.get_player()
	
	if act.actor_id == player.id then
		if act.category == 8 or act.category == 4 then
			castdelay = 7
		end
		
		if act.category == 4 or (act.category == 8 and act.param == 28787) then
			windower.send_command('gs c update')
		end
		
		if act.category == 4 and hasbuff(569) and act.param > 797 and act.param < 828 then
			coroutine.sleep(1.2)
			buffedbubble = windower.ffxi.get_mob_by_target("pet").id
		end
	end
end)


windower.register_event('zone change',function()
    movementarray = nil
	movementarray = {}
	touched = nil
	touched = {}
	tagged = nil
	tagged = {}
	
	windower.send_command('gs c update;bub on')
end)

function hasbuff(buffid)
	local player = windower.ffxi.get_player()

	for i,v in pairs(player.buffs) do
		if v == buffid then
			return true
		end
	end
	return false
end

function cancast()
	local player = windower.ffxi.get_player()

	for i,v in pairs(player.buffs) do
		if v == 2 or v == 7 or v == 10 or v == 19 or v == 6 or v == 28 or v == 29 then
			return false
		end
	end
	return true
end

windower.register_event('incoming chunk', function(id, data)
	if id == 0x029 then
		local p = packets.parse('incoming',data)
		if p["Message"] == 40 and p["Actor"] == windower.ffxi.get_player().id then
			windower.send_command('gs c update;bub off')
			print("Bubbler: Can't cast geomancy here. Disabled")
		end
	end
end)