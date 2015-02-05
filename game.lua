require "camera"
require "class/Player"
require "class/Enemy"

local game = {
	map    = nil,
	player = nil,
	score  = 0
}

local map, player -- shortcuts inside the module
local mapPixelWidth, mapPixelHeight -- Todo: add to map ?
local enemies = {}
local music, deadSound

function game.load(window)
	local sti = require "lib/sti"

	-- Load lua map from Tiled
	map = sti.new("map/world11")
	game.map = map
	tileSize = map.tilewidth -- TODO: local
	mapPixelWidth = map.width*tileSize*scale
	mapPixelHeight = map.height*tileSize*scale

	-- Set x camera bound
	camera:setBounds(0, 0, mapPixelWidth - window.width*scale, 0)

	-- World
	local physicsWorld = love.physics.newWorld()
	world = { -- TODO: local
		gravity = 41.32,
		ground  = window.height - tileSize
	}

	-- Collision objects
	collision = map:initWorldCollision(physicsWorld)

	-- Player
	player = Player:new(window.width/2, world.ground - tileSize)
	game.player = player 

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
    		enemy:update(dt, map)
        end

    	self.sprites.player:update(dt, map)
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

function game.update(dt, window)
	-- Update map including player and enemies sprites
	map:update(dt)

	camera:setPosition((player.x - window.width/2) * scale, 0)

	for i, enemy in pairs(enemies) do
		if enemy.stateX == "standing" then
			if enemy.x < (camera._x/scale + window.width) then
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
					game.score = game.score + 100
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

function game.draw(window)
	camera:set()

	-- Background color
	love.graphics.setBackgroundColor(100, 0, 0)

	-- Draw Range culls unnecessary tiles
	map:setDrawRange(-camera._x/scale, 0, window.width, window.height)

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
end

function game.stop()

end

function game.restart()

end	

function game.keypressed(key)

end

function game.keyreleased(key)
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

return game