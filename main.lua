require "camera"
require "Player"

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
	physicsWorld = love.physics.newWorld()
	world = {
		gravity = 41.32,
		ground  = windowHeight - tileSize
	}

	-- Collision objects
	collision = map:initWorldCollision(physicsWorld)

	-- Player
	player = Player:new()
end

function love.update(dt)
	-- -- Avoiding too large dt
	-- if dt > 0.05 then 
	-- 	dt = 0.05
	-- end

	map:update(dt)
	player:update(dt)

	camera:setPosition((player.x - windowWidth/2) * scale, 0)

	if love.keyboard.isDown('d', 'right') and player.stateX ~= "movingLeft" then
		player:moveRight()
	end

	if love.keyboard.isDown('q', 'left') and player.stateX ~= "movingRight" then
		player:moveLeft()
	end

	if love.keyboard.isDown(' ') then
		player:jump()
	end	
end

function love.draw()
	camera:set()

	-- Background color
	love.graphics.setBackgroundColor(107, 140, 255)

	-- Draw Range culls unnecessary tiles
	map:setDrawRange(-camera._x/scale, 0, windowWidth, windowHeight)

	-- Draw objects
	map:draw()
	player:draw()

	if debug then
		-- Draw Collision Map
		love.graphics.setColor(255, 0, 0, 255)
		-- map:drawWorldCollision(collision)

		-- Reset color
		love.graphics.setColor(255, 255, 255, 255)
		-- Reset translation if the camera is moving 
		if player.x > windowWidth / 2 then
			love.graphics.translate((player.x - windowWidth/2),0)
		end

		-- Display FPS and player information
		love.graphics.print("fps : " .. love.timer.getFPS(), 2, 0, 0, 1/scale, 1/scale)
		love.graphics.print("x : " .. string.format("%.1f", player.x), 2, 15/scale, 0, 1/scale, 1/scale)
		love.graphics.print("y : " .. string.format("%.1f", player.y), 2, 30/scale, 0, 1/scale, 1/scale)
		love.graphics.print("velocity x : " .. string.format("%.1f", player.velocityX), 2, 45/scale, 0, 1/scale, 1/scale)
		love.graphics.print("velocity y : " .. string.format("%.1f", player.velocityY), 2, 60/scale, 0, 1/scale, 1/scale)
		love.graphics.print("tile x : " ..  math.floor(player.x / tileSize) +1, 2, 75/scale, 0, 1/scale, 1/scale)
		love.graphics.print("tile y : " .. math.floor(player.y / tileSize) +1, 2, 90/scale, 0, 1/scale, 1/scale)
		love.graphics.print("state x : " .. player.stateX, 2, 105/scale, 0, 1/scale, 1/scale)
		love.graphics.print("state y : " .. player.stateY, 2, 120/scale, 0, 1/scale, 1/scale)
		love.graphics.print("life : " .. player.life, 2, 135/scale, 0, 1/scale, 1/scale)
	end

	camera:unset()
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
	if key == "q" or key == "left" then
		player.velocityX = 0
		player.stateX = "standingLeft"
	elseif key == "d" or key == "right" then
		player.velocityX = 0
		player.stateX = "standingRight"
	end
end

function math.clamp(x, min, max)
	return x < min and min or (x > max and max or x)
end