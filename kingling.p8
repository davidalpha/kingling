pico-8 cartridge // http://www.pico-8.com
version 35
__lua__


state = {}
-- STATES
function _init()
	show_menu()
end

function _update()
	state.update()
end

function _draw()
	state.draw()
end


-- STATE: MENU

function show_menu()
	state.update = menu_update
	state.draw = menu_draw

end

function menu_update()
	if btn(4) then
		show_game(1)
	end
end

function menu_draw()
	cls()
	print("press x to start",32,64,9)
	
end

-- STATE: LEVEL_PASS

function show_level_passed(current_level)
	state.update = level_passed_update
	state.draw = level_passed_draw

end

function level_passed_update()
	if btn(4) then
		show_game(level_id+1)
	end
end

function level_passed_draw()
	cls()
	print("level cleared!")
	print("press x to start",32,64,9)
end


-- STATE: GAME OVER

function show_game_over()
	state.update = game_over_update
	state.draw = game_over_draw

end

function game_over_update()
end

function game_over_draw()
end


-- STATE: GAME, set the level thats going to be played

function show_game(level)
	game_init()
	set_level(level)
	state.update = game_update
	state.draw = game_draw

end


function game_init()
	
	game_over = false
	start_screen = true
	target = 0

	-- anim
	banana_timer = 0
	blast_timer = 0
	banana_anim = 16
	game_timer = 0
	game_time_counter = 0
	
	--physics
	gravity = 4
	friction = 0.45

	--player 
	player={
    -- start coords
	x=4,
    y=64,
	-- sprite
    w=8,
    h=16,
    flp=false,
	-- movement
	--jumps
	j_force=10, --initial y force when jumping
	x_force=2, -- initial x force when jumping
	y_acc=1, -- accel modifiers (for lerps)
	x_acc=1.4,
	--climbing
    c_acc=0.3,
	max_yspd=3,
	-- states
	jumped=false,
	climbing=true,
	blasted=false,
	inbarrel=false,
	barrel_id=100,
	score=0
  	}

	--Objects
	barrels = {}
	bananas = {}
	platforms = {}
	tires = {}

	-- barrel blast
	blast={
	spr=40,
	x=0,
	y=0,
	show=false
	}

	--general
	t = 0 --general timer

	--waves
	evens = {2,2,4,4,4,6,6,6,8,8}
	odds = {3,3,3,5,5,5,5,7,7,7}
	wave_types = {"xsine","ysine","slime","leafs"}
	wavetimer = 0
	waveintensity = 5
	wave_index = 1
	shuffle(evens)

end

-- math helpers

function shuffle(t)
    for n=1,#t*2 do -- #t*2 times seems enough
        local a,b=flr(1+rnd(#t)),flr(1+rnd(#t))
        t[a],t[b]=t[b],t[a]
    end
    return t
end


function box_hit(
	x1,y1,
	w1,h1,
	x2,y2,
	w2,h2)

	hit=false
	local xd=abs((x1+(w1/2))-(x2+(w2/2)))
	local xs=w1*0.5+w2*0.5
	local yd=abs((y1+(h1/2))-(y2+(h2/2)))
	local ys=h1/2+h2/2
	if xd<xs and yd<ys then 
		hit=true 
	end

	return hit
end

-- LEVELS

function set_level(level)
	level_id = level
	--LEVELS
	--examples:
		--level_time_limit = 60
		--music(0) -- play music from pattern 0
		--create_wave(rnd(6)+5,rnd(2)+1,"xsine") --start game with a wave
		--create_barrel(0,12,64,"right","siney",0.3) -- create a barrel with rightsided opening going up and down
		--create_barrel(1,116,64,"left","siney",0.3)
		--create_barrel(2,64,12,"bottom","sinex",0.3)
		--create_barrel(3,100,80,"top","sinex",0.2)
		--create_barrel(1,100,64,"top","sinex",0.3)
		--create_platform(1,32,100,"has_tire","siney",1)
		--create_tire(1,32,100,56,false)
		--create_platform(2,90,100,"has_tire","siney",1)
		--create_tire(2,90,100,56,false)

	--levelpicker

	if level_id == 1 then
		--level 0
		level_time_limit = 10
		target = 3
		create_platform(1,22,100,"has_tire","siney",1.5)
		create_tire(1,22,100,56,false)
		create_platform(2,48,100,"has_tire","siney",1)
		create_tire(2,48,100,56,false)
		create_platform(3,78,100,"has_tire","siney",1.5)
		create_tire(3,78,100,56,false)
		create_platform(4,104,100,"has_tire","siney",1)
		create_tire(4,104,100,56,false)
	end

	if level_id == 2 then
		--level 0
		level_time_limit = 30
		target = 3
		create_platform(1,32,100,"has_tire","followx",1)
		create_tire(1,32,100,56,false)
		create_barrel(1,64,12,"bottom","siney",1)

	end
end

-- CREATE FUNCTIONS

-- Barrels
-- id=auto,x,y,type of orientation: top, bottom, right, left,type of movement,movement modifier
function create_barrel(id,x,y,type,move,mod)
   barrel={id=id,x=x,y=y,type=type,move=move,mod=mod}
   add(barrels,barrel)
end


-- Platforms
function create_platform(id,x,y,type,move,mod)
	platform={id=id,x=x,y=y,type=type,move=move,mod=mod}
	add(platforms,platform)
end


--Tires
function create_tire(id,x,y,spr,anim)
	tire={id=id,x=x,y=y,spr=spr,anim=anim}
	add(tires,tire)
end

--Spikes
function create_spike(id,x,y)
	spike={id=id,x=x,y=y}
	add(spike,spikes)
end

-- Bananas

function create_banana(id,x,y,yspd,type)
   banana={id=id,x=x,y=y,yspd=yspd,type=type}
   add(bananas,banana)
end

function create_wave(size,yspd,type)
	if type == "xsine" then
		for i=1,size do
			create_banana(i,64,i*4,yspd,type) 
		end
	end
	if type == "ysine" then
		offs = flr(128/(size))
		tx = flr(offs/2)
		for i=0,size do
			create_banana(i,((offs*i)+tx),0,yspd,type) 
		end
	end
	if type == "slime" then
		offs = flr(128/(size))
		tx = flr(offs/2)
		for i=0,size do
			create_banana(i,((offs*i)+tx),0,yspd,type) 
		end
	end
	if type == "leafs" then
		offs = flr(128/(size))
		tx = flr(offs/2)
		for i=0,size do
			create_banana(i,((offs*i)+tx),0,yspd,type) 
		end

	end
end



-- UPDATE FUNCTIONS

function barrel_update()
	for barrel in all(barrels) do
	--mod offsets sine
		if barrel.move == "sinex" then
			ti = t*(3*barrel.mod)
			barrel.x = barrel.x + sin(ti/80)*2
		end
		if barrel.move == "siney" then
			ti = t*(3*barrel.mod)
			barrel.y = barrel.y + sin(ti/80)*2
		end
	-- mod slows move
		if barrel.move == "followx" then
			barrel.x = (player.x*barrel.mod)
		end
	--mod slows move
		if barrel.move == "followy" then
			barrel.y = (player.y*barrel.mod)
		end
	end 
end



function platform_update()
	for platform in all(platforms) do
	--mod offsets sine
		for tire in all (tires) do
			if tire.id == platform.id then
				tire.x = platform.x
				tire.y = platform.y
			end
		end
		if platform.move == "static" then
			platform.x = platform.x
		end
		if platform.move == "sinex" then
			ti = t*(3*platform.mod)
			platform.x = platform.x + sin(ti/80)*2
		end
		if platform.move == "siney" then
			ti = t*(3*platform.mod)
		 platform.y = platform.y + sin(ti/80)*2
		end
	-- mod slows move
		if platform.move == "followx" then
		 platform.x = (player.x*platform.mod)
		end
	--mod slows move
		if platform.move == "followy" then
		 platform.y = (player.y*platform.mod)
		end
	end

end


-- PLAYER -- All player functions, gets called in update()
function player_update()

-- check to see if the jump button was STILL pressed on the next frame

if jump_pressed == true and btn(🅾️) then
	jump_still_pressed = true
else
	jump_still_pressed = false
end

if btn(🅾️) then
	jump_pressed = true
else
	jump_pressed = false
end

-- MOVEMENTS

-- apply physics when not climbing

	if not player.climbing then
		player.y += gravity
	end

	if player.inbarrel then
		player.x = pbarrel.x
		player.y = pbarrel.y
		if btn(🅾️) and not jump_still_pressed then
			player.inbarrel = false
			player.blasted = true
			btimer = 0	
		end
	end

	if player.blasted then
		btimer += 1
		blast.x = pbarrel.x + (pbarrel.x-player.x)/8
		blast.y = pbarrel.y + (pbarrel.y-player.y)/8
		blast.show = true
		if btimer < 10 then
			if pbarrel.type == "right" then
				player.x = player.x + 7
				player.x += 0.6-(btimer*0.15)
				player.y -= 5-(btimer*0.1)
			end
			if pbarrel.type == "left" then
				player.x = player.x - 7
				player.x -= 0.6-(btimer*0.15)
				player.y -= 5-(btimer*0.1)
			end
			if pbarrel.type == "top" then
				player.y = player.y - 5
				player.y -= 8-(btimer*0.2)
			end
			if pbarrel.type == "bottom" then
				player.y = player.y + 7
				player.y += 0.6-(btimer*0.15)
			end
		else
		player.blasted = false
		end
	end


-- if jump button is held down increase y. if not cancel jump state

	if btn(🅾️) and player.jumped then
			jumpforce = player.j_force*y_acc
			player.y -= player.j_force*y_acc
			if y_acc >= 0 then
				y_acc -= 0.05
			else
				y_acc = 0
			end
	elseif not btn(🅾️) then
		player.jumped = false
	end

-- jump pressed while climbing. set state to jumped and init jump values
	if btn(🅾️) and player.climbing and not player.jumped then
		player.climbing = false
		player.jumped = true
		y_acc = player.y_acc
		x_acc = player.x_acc
		xspd = 0
		last_dir = 0
	end

	-- Aerial (x) movement
	if not player.climbing then
		if btn(⬅️) then
			player.flp = true
			xspd = player.x_force*x_acc
			if x_acc >= 0 then
				x_acc -= 0.02
			else
				x_acc = 0
			end
			xdir = -1
			last_dir = xdir

		elseif btn(➡️) then
			player.flp = false
			xspd = player.x_force*x_acc
			if x_acc >= 0 then
				x_acc -= 0.02
			else
				x_acc = 0
			end
			xdir = 1
			last_dir = xdir
		
		else 
			if xspd >= 0 then
				xspd -= 0.5
			else
				xspd = 0
			end
			xdir = last_dir
		end
		player.x += xspd*xdir
	end
	

	-- climbing (y) movement
	if not player.jumping then
		if btn(⬆️) then
			if yspd <= player.max_yspd then
			 yspd += player.c_acc
			else
			 yspd = player.max_yspd
			end
			ydir = -1*friction
		elseif btn(⬇️) then
			if yspd <= player.max_yspd then
			 yspd += player.c_acc
			else
			 yspd = player.max_yspd
			end
			ydir = 1
		else 
			if yspd != null and yspd > 0 then
				yspd -= 0.2
			else
				ydir = 0
				yspd = 0
			end
		end
		player.y += yspd*ydir
	end

-- COLLISIONS

-- vine collision
	if not btn(🅾️) and player.x < 5 or player.x > 118 then
		player.jumped = false
		player.climbing = true
	end

-- tire collision
	for tire in all(tires) do
		if box_hit(player.x,player.y,player.w,player.h,tire.x,tire.y,8,8) then
			tire.anim = true
			player.jumped = true
			y_acc = player.y_acc
			x_acc = player.x_acc
		end
	end

-- -- platform collision
-- 	for platform in all(platforms) do
-- 		if box_hit(player.x,player.y,player.w,player.h,platform.x,platform.y,16,24) then
-- 			player.x +=platform.x	
			
-- 		end	
-- 	end

-- barrel collision
	for barrel in all(barrels) do
		if box_hit(player.x,player.y,player.w,player.h,barrel.x,barrel.y,16,16) then
			--xbarrel.anim = true
			if not player.blasted then
				player.inbarrel = true
				pbarrel = barrel
			end
		end	
	end

--banana collision
	for banana in all(bananas) do
		if not player.inbarrel then
			if box_hit(player.x,player.y,player.w,player.h,banana.x,banana.y,8,8) then
					banana.type = 'picked'
					player.score += 1
			end
		end
	end

-- general out of bounds collision
-- top of screen
	if player.y < -16 then
		player.y = -16
	end

-- left border
	if player.x < 2 then
		player.x = 2
	end
--right border
	if player.x > 126 then
		player.x = 126
	end
--falls in pit
	if player.y > 128 then
		run()
	end

end



function banana_update()
i = 0
	for banana in all(bananas) do --banana update loop
		-- vertical snaking line
		if banana.type == "xsine" then
			ti = t+banana.id*4
			banana.x = 64+(sin(ti/50)*8)
			banana.y += banana.yspd
			i+=1
		end
		--spaced line with alernating sine
		if banana.type == "ysine" then
			if i % 2 == 0 then
				ti = t+1.5
			else
				ti = t
			end
			banana.y = banana.y + (sin(ti/20)*banana.yspd) + 0.5
			i+=1
		end
		-- spaced line that falls like a leaf
		if banana.type == "leafs" then
			banana.x = banana.x + sin(t/50)*0.5
			banana.y += banana.yspd + sin(t/20)
		end
		--spaced line, slows down and speeds up
		if banana.type == "slime" then
			banana.y += banana.yspd + sin(t/20)
		end

		--picked up
		if banana.type == "picked" then
			banana.y -= (banana.y*0.5)
			banana.x += ((128-banana.x)*0.1)
		end
		
		-- collisions and out of bounds
	
		if banana.y>130 then --delete banana if off screen
			del(bananas,banana)
		end

		if banana.type == "picked" and banana.y < 0 or banana.x > 124 then
			del(bananas,banana)
		end

	
	end

end


function game_update()


	-- check if we got a game over or if we passed the level (target score was obtained before timer ran out)
	if game_over then
		if level_passed then
			show_level_passed()
		else
			show_game_over()
		end
	else

	-- if not game over game runs until time limit is reached.

		game_timer += 1
		if game_timer == 20 then
			game_time_counter += 1
				if game_time_counter == 30 then
					game_over = true
					if player.score >= target then
						level_passed = true
					end
				end
			game_timer = 0
		end 
		

		

		-- ANIM


		-- general anim timer
		banana_timer += 1
		
		-- update every 10 ms
		if banana_timer == 10 then
		-- spin bananas
			if banana_anim == 23 then
				banana_anim = 16
			else
				banana_anim += 1
			end
		banana_timer = 0
		end

		-- tire hit
		for tire in all(tires) do
			if tire.anim then
				if tire.spr < 58 then
					tire.spr += 1
				else
					tire.spr = 56
					tire.anim = false
				end
			end
		end


		-- barrel blast anim
		if blast.show then
			blast_timer += 1
			if blast_timer == 5 then
				blast.spr += 1
				if blast.spr > 42 then
					blast.show = false
					blast.spr=40
				end
				blast_timer=0
			end
		end

		-- update functions

		player_update()
		platform_update()
		barrel_update()
		banana_update()

		
		-- Make waves, objects etc based on timers here


		if wavetimer==60 then --every 3 seconds spawn wave
			create_wave(evens[wave_index],rnd(2)+1,rnd(wave_types))
			wave_index += 1
			wavetimer=0 -- reset timer
		end
		t+=1
		wavetimer+=1
	end
end

function game_draw()

	cls()
	-- draw map
	map()

	-- draw all bananas
	for banana in all(bananas) do 
		spr(banana_anim,banana.x,banana.y)
	end

	-- draw all vines (TODO make create_vines())
	vines = {2,3}
	for i=0,12 do
		spr(2,0,i*8)
		spr(2,120,i*8)  
	end

	-- draw monkey

	if not player.inbarrel then
		if player.flp then
			--top
			spr(53,player.x,player.y,1,1,true,false)
			--bottom
			spr(54,player.x,player.y+8,1,1,true,false)
			--tail
			spr(55,player.x+8,player.y+8,1,1,true, false)
		else
			--top
			spr(53,player.x,player.y)
			--bottom
			spr(54,player.x,player.y+8)
			--tail
			spr(55,player.x-8,player.y+8)
		end
	end



	--draw all platforms
	for platform in all(platforms) do
		spr(49,platform.x-8,platform.y+8) -- left bot
		spr(33,platform.x-8,platform.y) -- left top
		spr(51,platform.x,platform.y+8) -- middle bot
		spr(35,platform.x,platform.y) -- middle top
		spr(50,platform.x+8,platform.y+8) -- right bot
		spr(34,platform.x+8,platform.y) -- right top
	end

	-- draw all tires
	for tire in all(tires) do
		spr(tire.spr,tire.x,tire.y) -- tire
	end


	--draw barrels
	for barrel in all(barrels) do
		if barrel.type == "top" then
			-- barrel on x axis (top open)
			spr(59,barrel.x,barrel.y,2,1) -- left top
			spr(61,barrel.x,barrel.y+8,2,1) -- right bot
		elseif barrel.type == "bottom" then
			-- barrel on y axis (right side open)
			spr(59,barrel.x,barrel.y+8,2,1,false,true) -- left top
			spr(61,barrel.x,barrel.y,2,1,false,true) -- right bot
		elseif barrel.type == "right" then
			-- barrel on y axis (right side open)
			--spr(43,ybarrel.x,ybarrel.y+8) -- left bot
			spr(27,barrel.x,barrel.y,2,1) -- left top
			spr(43,barrel.x,barrel.y+8,2,1) -- right bot
		elseif barrel.type == "left" then
			-- barrel on y axis (right side open)
			--spr(43,ybarrel.x,ybarrel.y+8) -- left bot
			spr(27,barrel.x,barrel.y,2,1,true) -- left top
			spr(43,barrel.x,barrel.y+8,2,1,true) -- right bot

		end
	end

	-- show barrel blast
	if blast.show then
		spr(blast.spr,blast.x,blast.y)
	end

	-- score prints
	print(player.score,114,6,9)
	print(game_time_counter,64,6,9)


	-- debug

end

__gfx__
0aaaaaa000000000000b300000003b001111111111111111222222222222222222222222222222229999999900000000077aaaa00aa777a00aaaa7700aaaaaa0
a111111900088000000b3000000b3000111111112121212122222222222222222222222229292929999999990000000071111119a1111119a111111aa1111119
a1aaaa190089980000003b00000b3000111111111212121221212121222222222222222292929292999999990000000071aaaa19a1aaaa19a1aaaa1aa1aaaa19
a1a99919089aa98000003b0000003b001111111121212121222222222222222222222222292929299999999900000000a1a9991971a99919a1a99919a1a9991a
a1a99119089aa9800000b00000003b001111111122222222222222222222222222222222292929299999999910101010a1a9911971a99119a1a99119a1a9911a
a1a1191900899800000b30000000b0001111111121212121222222222222222222222222999999999999999900000000a1a11919a1a1191971a11919a1a11917
a111111900088000000b3000000b30001111111122222222222222222222222222222222999999999999999901010101a1111119a111111971111119a1111117
099999900000000000003b00000b3000111111111212121222222222222222229292929299999999999999991010101009999990099999900aa99990099aa770
00049000000044000000400000004400000009400000040000004000000040000000000000000000000000000000000000000000000000000000000000000000
0004a700000940000094900000049000007a400000094000009a9000000490000000000000000000000000000000000000000000000000000000000000000000
00009a90000a7900009790000097a00009a90000007aa00000a7a000000aa7000000000000000000000000000000022255222000000000000000000000000000
00009790000aa90000aaa000009aa00009790000007a900000a7a0000009aa000000000000000000000000000005544554425620000000000000000000000000
000097900007a90000aaa000009a70000979000000aa900000a7a0000009aa0000000000000000000000000000dd244dd44d61d0000000000000000000000000
0009aa900007a900009a9000009a700009aa900000aa900000a7a0000009aa00000000000000000000000000006222dd22261116000000000000000000000000
099aaa0009aaa90000979000009aaa9000aaa990007aa990009a9000099aa7000000000000000000000000000074446644461116000000000000000000000000
00aa700000a99000000a000000099a000007aa00000aaa000004000000aaa0000000000000000000000000000074447744461116000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000066660006060060006000000072226622261116000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000067767606d7d67d606600060006444dd44461116000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000676677606775777dd000000d00dd222dd22d61d0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000667777d067750577000000000005544554445620000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007777767607d00077000000000000022255222000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000666766666770756000000d60000000000000000000000000000000000000000
000000000ffffffffffffff0ffffffff0000000000000000000000000000000006776dd00d777dd6d0000d600000000000000000000000000000000000000000
00000000999999999999999999999999000000000000000000000000000000000066d000066dd0606d0000000000000000000000000000000000000000000000
000000009999999999999999999999999999999900888800888888800000000800d1110000000000000000000000777777700000004244242442400000000000
00000000999999999999999999999999999999990888888888888880000440080611661000000000000000000006111111160000004244242442400000000000
0000000044949449499449429944449442999292ff47f70044fff440004000046116005100d11100000000000006611111760000000d4424244d000000000000
0000000022224222244224204422224222444242ff919100244f440000400444d1600025061166100d1111100042667777624000000d6644466d000000000000
000000000244244242242200222222222222222244fffff02444440000044000d160022561160051d11666110042442424424000000056777650000000000000
000000000024222222222000244420244224442204ffffff444244000000000011162251d1600025116002510052442424425000000000000000000000000000
0000000000020200202200002222000222202220884ffff0ff0ff000000000000111551011162251111555110055d52425d55000000000000000000000000000
000000000000000000000000000000000000000088888800ff0ff0000000000000111100011155100111111000455d666d554000000000000000000000000000
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999900000000000000000000000000000000
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999900000000000000000000000000000000
9999aa3993aa99999999333993339999999999999999999999999999999999999999999999999999999999999999999900000000000000000000000000000000
99b33b3333b3339999333333333333999999999999999999999999999999999999999999999999bb3999b9999999999900000000000000000000000000000000
933b3333333333b99333333333333339999999999999999999999999999999999999999999999399339399999999999900000000000000000000000000000000
93333ddbbdd33b3993333dd33dd333399999999999999999999999999999999999999999999aaa99939399b33999999900000000000000000000000000000000
233dddbaabddd332233ddd3333ddd3329999999999999999999999999999999999999999993bb33b33239a333399999900000000000000000000000000000000
2322dd3bb3dd2232232ddd3333ddd23299999999999999999999999999999999999999999b999933b3339b399939999900000000000000000000000000000000
2322dd3333dd22322322dd3333dd223299999999999999aaaa999999999999999999999999bbb933b3b3b3399999999900000000000000000000000000000000
2d222d3333d222d22d222d3333d222d29999999999999bbbbbb999999999999999999999999333b3b2b3b339bb99999900000000000000000000000000000000
2dd22ddbbdd22dd22dd22dd33dd22dd2999997aaab99b322223b99baaa7999999999999999b33323b2b3b3bb99b9999900000000000000000000000000000000
2ddd2dd33dd2ddd22ddd2dd33dd2ddd29999a99333b933baab339b33399a9999999999999b3323323bb23b33b999999900000000000000000000000000000000
2ddd2dd22dd2ddd22ddd2dd22dd2ddd2999b333333333b3bb3b333333333b999999999993332eeb33333bb333b99999900000000000000000000000000000000
2dddddd22dddddd22dddddd22dddddd299b331331331b333333b133133133b999999999e33e2ebe444444b2233399a9900000000000000000000000000000000
333dddd22dddd333333dddd22dddd33393313119999443b33b3442229113133999999eee33e2ebee222299bee339399900000000000000000000000000000000
33333dd22dd3333333333dd22dd33333b3319999eeee4b1331b422222922133be999eeeee3e2eee2444493beeeb3999900000000000000000000000000000000
00000000000000000000000000000000b339999eeeee413bb31429992222933bee9eeeeeeee2eee2e44eee33e33ee99900000000000000000000000000000000
000000000000000000000000000000003399eeeeeeeee3b33b3ee22222222233eeeeeeeeeee2eee2e44e222333222e9900000000000000000000000000000000
000000000000000000000000000000003eeeeeeeeeeeeb1331b2222222222223eeeeeeeeeeee2ee2e2222e33333e22e900000000000000000000000000000000
000000000000000000000000000000003eeeeeeeeeeee13333122eee222222232eeeeeeeeeeee22ee442e332b233e2ee00000000000000000000000000000000
00000000000000000000000000000000eeeeeeeeeeeee3333332eeeee222e2222eeeeeeeeeeeeeeee44ee334b433eeee00000000000000000000000000000000
00000000000000000000000000000000eee22eeee222e33bb332eeee22eeee222eeeeebbeeeeeeeee44ee3e232e3eeee00000000000000000000000000000000
00000000000000000000000000000000ee2222ee22222eb33beeeeee22eeee222ebaa3323bbeeeeee22ee3ee3ee3eeee00000000000000000000000000000000
00000000000000000000000000000000e2eee2222eee2e3333eeeee2222ee22ee33332b3233beeeee44eeeee3eeeeeee00000000000000000000000000000000
00000000000000000000000000000000eee22222222eee5335ee2ee22e2ee2eee3eeeb3322e3beeee22ee2ee3eeeeeee00000000000000000000000000000000
00000000000000000000000000000000ee22222222222e5335eee2e22e2ee2eee3eee33e22ee3eeee44e2eee2ee2eeee00000000000000000000000000000000
00000000000000000000000000000000e2ee222222ee2244442ee2e22ee22eeeeeeee33ee22eee2ee22e2e2e2e2eeeee00000000000000000000000000000000
00000000000000000000000000000000e2eee2222eeee24444e2e222eeeeeeeeeeeee33ee22e2e2e224e222e2ee2e2ee00000000000000000000000000000000
00000000000000000000000000000000eeeeee22eeeeee9449ee2222eeeeeeeeee2223eee22ee2e2222222222e2222ee00000000000000000000000000000000
00000000000000000000000000000000eeeeee22eeeee24ff42e2222ee222eeee22222eee222e222222222222222222e00000000000000000000000000000000
00000000000000000000000000000000ee222e22eeee224444222222e222222e2222222e22222222222222222222222200000000000000000000000000000000
00000000000000000000000000000000e22222222222229449222222222222222222222222222222222222222222222200000000000000000000000000000000
__map__
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808080808080808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4b4445464748494a4b44454647484900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5a5b5455565758595a5b54555657585900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6a6b6465666768696a6b64656667686900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a7b7475767778797a7b74757677787900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
311000001b7233f7001b735000001b7251b7331b7251b7003f7002e7003f7001b725337001b7003f7001b7233f7001b7331b7253f7001b7001b7351b7230070300700007001b7001b7001b7001b7001b7351b700
001000200050002504275150251327500025002750002500275000250027515025132750002500275150251327500025002751502513275000250027500025002750002500275150251627500025002750002500
491000000c00016000240002400024000180003f000000002401324043240431803424023240130c0030c00000003070010c0000c000160000c0000c000000000000000000240432403324025240130000300000
901000000324503215032150324503245032150324503215032150324503215032150324503215032150324503215032150324503215032150324503215032150324503215032150324503215032150324503215
01100000264001a4001a4000e400294001d4001d4001d400264001a4001a4000c4002b4001f4001f4001f4001d40011400114000f4001a4000e4000e4000e4001a4000e4000e4000e400184000c4000c4000c400
001000001375613752137521375213742077400772007710137511375213752137521374013753077231375305700117000570011700137551375213755137521375613752137521375213742077400772007710
011000001475614752147521475214742087400872008710147511475214752087520874014753147231475305700117000570011700147551475214755147521475614752147521475214742147401472014710
0110000014551145521455214550145401454214540145401b5411b5301b5161b5421b5301b5161b5421b5301b5161453014510015001453001500145101b5001b555015001b5501b552145001b5521b55201500
d11000000c0420c03700037000520f0300f0510003117052180511b0321b0540c0551603318052160350f05207052070500f050110521305313050110550f0520f0520f0570c057000070c0530f0500000000000
__music__
02 42040149
00 41040307
00 41040109
00 41040308
00 41040209
00 41030208
00 02040106
00 41040307
00 01040302
02 41034302
00 41464344
02 41424344

