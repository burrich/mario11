local sti = require "lib/sti"

require "camera"

function love.load()
	-- Window size
	windowWidth  = love.graphics.getWidth()
	windowHeight = love.graphics.getHeight()

	-- Set camera bounds
	camera:setBounds(0, 0, windowWidth, windowHeight)

	-- Load lua map from Tiled
	map = sti.new("map/world11")
	tileSize = map.tilewidth
	mapPixelWidth = map.width*tileSize

	-- World
	physicsWorld = love.physics.newWorld()
	world = {
		gravity = 41.32,
		ground  = windowHeight - tileSize*scale
	}

	-- Collision objects
	collision = map:initWorldCollision(physicsWorld)

	-- Player
	player = {}
		player.width        = tileSize
		player.height       = tileSize
		player.xOrigine     = windowWidth/2-- - player.width/2
		player.x            = player.xOrigine
		player.y            = world.ground - tileSize
		player.velocityX    = 0
		player.velocityY    = 0
		player.jumpHeight   = 5*tileSize
		player.ySpeed       = 3
		player.fallingSpeed = 3
		player.speed        = 150
		player.jumping      = false
		player.falling      = false
		player.state        = "stand"
		-- player.moving     = false

	function player:moveLeft()
		self.velocityX = -self.speed
		player.state = "movingLeft"
	end

	function player:moveRight()
		self.velocityX = self.speed
		player.state = "movingRight"

	end

	function player:jump()
		if not self.jumping then
			self.velocityY = -self.jumpHeight
			self.jumping = true
		end
	end

	function player:update(dt)
		if self.jumping or self.falling then
			self.velocityY = self.velocityY + world.gravity*dt*self.ySpeed
		end

		nextX = self.x + self.velocityX*dt
		nextY = self.y + self.velocityY*dt*self.ySpeed

		-- Bottom
		if self.velocityY > 0 then
			if self:isColliding(self.x , nextY+self.height) 
			or self:isColliding(self.x+self.width -1, nextY+self.height) then

				self.jumping = false
				self.velocityY = 0
				self.y = nextY - nextY % tileSize
			else
				self.y = nextY
			end
		end

		-- Top
		if self.velocityY < 0 then
			if self:isColliding(self.x , nextY) 
			or self:isColliding(self.x+self.width -1, nextY) then

				self.velocityY = 0
				self.y = nextY + tileSize - nextY % tileSize
			else
				self.y = nextY
			end
		end

		-- Left
		if self.velocityX < 0 then
			if self:isColliding(nextX, self.y) 
			or self:isColliding(nextX, self.y+self.height -1) then

				self.x = nextX + tileSize - nextX % tileSize
			else
				self.x = nextX
			end
		end

		-- Right
		if self.velocityX > 0 then
			if self:isColliding(nextX+self.width, self.y) 
			or self:isColliding(nextX+self.width, self.y+self.height -1) then

				self.x = nextX - nextX % tileSize
			elseif not self:isColliding(nextX, self.y+self.height) then
				self.falling = true
				self.x = nextX
			else
				self.x = nextX
			end
		end
	end

	function player:draw()
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	end

	function player:isColliding(x, y)
		local tileX = math.floor(x / tileSize) +1
		local tileY = math.floor(y / tileSize) +1

		-- print("x : " .. tileX, "y : " .. tileY)

		if tileY < 1 or tileY > map.height then
			return true
		end
		-- print("collision : " .. tostring(map.layers["Collision"].data[13][1]))
		return map.layers["Collision"].data[tileY][tileX]
	end

	translateX  = 0
	translateY  = 0

	-- print("collision : " .. tostring(map.layers["Collision"].data[13][29])) -- x 19
end

function love.update(dt)
	-- -- Avoiding too large dt
	-- if dt > 0.05 then -- Or 0.02 ?
	-- 	dt = 0.05
	-- end

	if love.keyboard.isDown('d', 'right') and player.state ~= "movingLeft" then
		player:moveRight()
	end

	if love.keyboard.isDown('q', 'left') and player.state ~= "movingRight" then
		player:moveLeft()
	end

	if love.keyboard.isDown(' ') then
		player:jump()
	end

	map:update(dt)
	player:update(dt)

	camera:setPosition(player.x - windowWidth / 2, 0)
end

function love.draw()
	camera:set()
	love.graphics.scale(scale)

	love.graphics.setBackgroundColor(107, 140, 255)

	-- Draw Range culls unnecessary tiles
	-- map:setDrawRange(-translateX, translateY, windowWidth, windowHeight)

	-- Draw objects
	map:draw(scale) -- scale
	player:draw()

	if debug then
		-- Draw Collision Map
		love.graphics.setColor(255, 0, 0, 255)
		map:drawWorldCollision(collision)

		-- Reset color and translation
		love.graphics.setColor(255, 255, 255, 255)
		-- if translation then
		-- 	camera:setPosition(translateX-(player.x - player.xOrigine), 0)
		-- end

		-- Display FPS and player information
		love.graphics.print("fps : " .. love.timer.getFPS(), player.x, 0)
		love.graphics.print("x : " .. string.format("%.1f", player.x), 5, 15)
		love.graphics.print("y : " .. string.format("%.1f", player.y), 5, 30)
		love.graphics.print("velocity x : " .. string.format("%.1f", player.velocityX), 5, 45)
		love.graphics.print("velocity y : " .. string.format("%.1f", player.velocityY), 5, 60)
		love.graphics.print("tile x : " ..  math.floor(player.x / tileSize) +1, 5, 75)
		love.graphics.print("tile y : " .. math.floor(player.y / tileSize) +1,5, 90)
	end

	print("tile x : " ..  math.floor(player.x / tileSize) +1)
	print("tile y : " .. math.floor(player.y / tileSize) +1)
	print("player x " .. player.x)

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
	if key == "q" or key == "left" 
	or key == "d" or key == "right" then
		player.velocityX = 0
		player.state = "stand"
	end
end

function math.clamp(x, min, max)
	return x < min and min or (x > max and max or x)
end