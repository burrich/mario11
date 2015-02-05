require "camera"
require "class/Player"
require "class/Enemy"

local player
local enemies = {}
local music, deadSound

function love.load()
	local sti = require "lib/sti"
	
	-- Window original size 
	-- Multiply by scale to get the real window size
	windowWidth  = love.graphics.getWidth()/scale
	windowHeight = love.graphics.getHeight()/scale

	-- Load lua map from Tiled
	map = sti.new("map/world11")
	tileSize = map.tilewidth
	mapPixelWidth = map.width*tileSize*scale
	mapPixelHeight = map.height*tileSize*scale

	-- Set x camera bound
	camera:setBounds(0, 0, mapPixelWidth - windowWidth*scale, 0)

	-- World
	local physicsWorld = love.physics.newWorld()
	world = {
		gravity = 41.32,
		ground  = windowHeight - tileSize
	}

	-- Collision objects
	collision = map:initWorldCollision(physicsWorld)

	-- Player
	player = Player:new()

	-- Enemies
	for _, enemyObj in pairs(map.layers['Enemies'].objects) do
		table.insert(enemies, Enemy:new(enemyObj.x, enemyObj.y))
	end

	-- Sprite layer
	map:addCustomLayer("Sprite Layer", 4)

	local spriteLayer = map.layers["Sprite Layer"]
	spriteLayer.sprites = {
		player = player,
		enemies = enemies
	}

	-- Update callback for Custom Layer
    function spriteLayer:update(dt)
        for _, enemy in pairs(self.sprites.enemies) do
    		enemy:update(dt)
        end

    	self.sprites.player:update(dt)
    end

    -- Draw callback for Custom Layer
    function spriteLayer:draw()
        for _, enemy in pairs(self.sprites.enemies) do
        	enemy:draw()
        end

    	self.sprites.player:draw()
    end

    -- Music
    deadSound = love.audio.newSource("sound/hit.wav", "static")
    music = love.audio.newSource("sound/MoonlightSonata.mp3")
	music:play()
end

function love.update(dt)
	-- Update map including player and enemies sprites
	map:update(dt)

	camera:setPosition((player.x - windowWidth/2) * scale, 0)

	for i, enemy in pairs(enemies) do
		if enemy.stateX == "standing" then
			if enemy.x < (camera._x/scale + windowWidth) then
				enemy:moveLeft()
			end
		else
			if enemy:isCollidingPlayer(player.x, player.y, player.width, player.height) then
				if player.stateY == "falling" or player.stateY == "jumpFalling" then
					enemy:dead()

					local kill = love.audio.newSource("sound/kill.wav", "static")
					kill:play()

					player.stateY = "standing"
					player:jump(tileSize*2.5)
					player.score = player.score + 100
				elseif player.life > 0 then
					player:dead()

					deadSound:play()

					for _, enemy in pairs(enemies) do
						enemy:stop()
					end

					break
				end
			end

			if enemy.y > mapPixelHeight/scale then
				table.remove(enemies, i)
			end

			if enemy.life == 0 then
				if enemy.deathTimer < enemy.deathTimerMax then
					enemy.deathTimer = enemy.deathTimer + dt
				else
					table.remove(enemies, i)
				end
			end
		end
	end

	if player.life ~= 0 then
		if love.keyboard.isDown('d', 'right') then
			player:moveRight()
		end

		if love.keyboard.isDown('q', 'left') then
			player:moveLeft()
		end

		if love.keyboard.isDown(' ') then
			player:jump()
		end	
	end
end

function love.draw()
	camera:set()

	-- Background color
	love.graphics.setBackgroundColor(100, 0, 0)

	-- Draw Range culls unnecessary tiles
	map:setDrawRange(-camera._x/scale, 0, windowWidth, windowHeight)

	-- Draw objects
	map:draw()

	if debug then
		-- Draw Collision Map
		love.graphics.setColor(255, 0, 0, 255)
		-- map:drawWorldCollision(collision)

		-- Reset color
		love.graphics.setColor(255, 255, 255, 255)
	end

	camera:unset()

	love.graphics.print("score : " .. player.score, 2, 0)

	if debug then
		love.graphics.print("fps : " .. love.timer.getFPS(), 2, 15)
		love.graphics.print("x : " .. string.format("%.1f", player.x), 2, 30)
		love.graphics.print("y : " .. string.format("%.1f", player.y), 2, 45)
		love.graphics.print("velocity x : " .. string.format("%.1f", player.velocityX), 2, 60)
		love.graphics.print("velocity y : " .. string.format("%.1f", player.velocityY), 2, 75)
		love.graphics.print("tile x : " ..  math.floor(player.x / tileSize) +1, 2, 90)
		love.graphics.print("tile y : " .. math.floor(player.y / tileSize) +1, 2, 105)
		love.graphics.print("state x : " .. player.stateX, 2, 120)
		love.graphics.print("state y : " .. player.stateY, 2, 135)
		love.graphics.print("life : " .. player.life, 2, 150)
	end

	if player.life == 0 then
		love.graphics.print("GAME OVER !", windowWidth/2  * scale - 40, windowHeight/2 * scale - 20)
	end
end

function love.resize(w, h)
	map:resize(w, h)
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.push('quit')
	end
	if key == '`' then
		debug = not debug
	end
end

function love.keyreleased(key)
	if player.life > 0 then
		if key == "q" or key == "left" then
			player.velocityX = 0
			player.stateX = "standingLeft"
		elseif key == "d" or key == "right" then
			player.velocityX = 0
			player.stateX = "standingRight"
		end
	end
end

function math.clamp(x, min, max)
	return x < min and min or (x > max and max or x)
end