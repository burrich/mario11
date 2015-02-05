local anim8   = require "lib/anim8"
local deadImg = love.graphics.newImage("assets/deadGoomba.png")
local sprites = love.graphics.newImage("assets/enemies.png")
local grid    = anim8.newGrid(16, 16, sprites:getWidth(), sprites:getHeight())

sprites:setFilter('nearest', 'nearest')
deadImg:setFilter('nearest', 'nearest')

Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y)
	local object = {
		width         = deadImg:getWidth(),
		height        = deadImg:getHeight(),
		x             = x,
		y             = y,
		velocityX     = 0,
		velocityY     = 0,
		speed         = 50,
		ySpeed        = 3,
		fallingSpeed  = 3,
		life          = 1,
		deathTimer    = 0,
		deathTimerMax = 0.5,
		stateX        = "standing",
		stateY        = "standing",
		anim          = anim8.newAnimation(grid('1-2', 2), 0.5)
	}

	setmetatable(object, self)

	return object
end

function Enemy:moveLeft()
	self.velocityX = -self.speed
	self.stateX = "movingLeft"
end

function Enemy:moveRight()
	self.velocityX = self.speed
	self.stateX = "movingRight"
end

function Enemy:stop()
	self.velocityX = 0
	self.velocityY = 0
	self.stateX = "stop" 
	self.stateY = "stop"
end

function Enemy:dead()
	self.life = 0
	self.velocityX = 0
	self.velocityY = 0
	self.stateX = "dead" 
	self.stateY = "dead"
end

function Enemy:isColliding(x, y, map)
	local tileX = math.floor(x / tileSize) +1
	local tileY = math.floor(y / tileSize) +1
	
	if tileY > map.height then
		return false
	end

	-- Map bounds collisions
	if tileY < 1 or tileY > map.height
	or tileX < 1 or tileX > map.width then
		return true
	end

	-- print("x : " .. tileX, "y : " .. tileY)
	-- print("collision : " .. tostring(map.layers["Collision"].data[13][1]))

	return map.layers["Collision"].data[tileY][tileX]
end

function Enemy:isCollidingPlayer(playerX, playerY, playerWidth, playerHeight)
	if self.life == 0 then
		return false
	end

	return self.x < playerX + playerWidth and
	       playerX < self.x + self.width and
	       self.y < playerY + playerHeight and
	       playerY < self.y + self.height
end

function Enemy:update(dt, map)
	-- Gravity application
	if self.stateY == "falling" then
		self.velocityY = self.velocityY + world.gravity*dt*self.ySpeed
	end

	local nextX = self.x + self.velocityX*dt
	local nextY = self.y + self.velocityY*dt*self.ySpeed

	-- Bottom
	if self.velocityY > 0 then
		if self:isColliding(self.x , nextY+self.height, map) 
		or self:isColliding(self.x+self.width -1, nextY+self.height, map) then

			self.stateY = "standing"
			self.velocityY = 0
			self.y = nextY - nextY % tileSize
		else
			self.y = nextY
		end
	end

	-- Left
	if self.velocityX < 0 then
		self.anim:update(dt)

		if self:isColliding(nextX, self.y, map) 
		or self:isColliding(nextX, self.y+self.height -1, map) then

			self.x = nextX + tileSize - nextX % tileSize
			self:moveRight()
		elseif not self:isColliding(nextX, self.y+self.height, map) then
			if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
				self.stateY = "falling"
			end

			self.x = nextX
		else
			self.x = nextX
		end
	end

	-- Right
	if self.velocityX > 0 then
		self.anim:update(dt)

		if self:isColliding(nextX+self.width, self.y, map) 
		or self:isColliding(nextX+self.width, self.y+self.height -1, map) then

			self.x = nextX - nextX % tileSize
			self:moveLeft()
		elseif not self:isColliding(nextX, self.y+self.height, map) then
			if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
				self.stateY = "falling"
			end

			self.x = nextX
		else
			self.x = nextX
		end
	end
end

function Enemy:draw()
	if self.life == 0 then
		love.graphics.draw(deadImg, self.x, self.y)
	else
		self.anim:draw(sprites, self.x, self.y)
	end
end