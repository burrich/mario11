-- TODO: small jumps

local anim8 = require "lib/anim8"

local standImg = love.graphics.newImage("assets/stand.png")
local jumpImg = love.graphics.newImage("assets/jump.png")
local deadImg = love.graphics.newImage("assets/dead.png")
local sprites = love.graphics.newImage("assets/mario.png")

sprites:setFilter('nearest', 'nearest')
standImg:setFilter('nearest', 'nearest')
jumpImg:setFilter('nearest', 'nearest')
deadImg:setFilter('nearest', 'nearest')

local grid = anim8.newGrid(16, 16, sprites:getWidth(), sprites:getHeight())
local rightWalkAnim = anim8.newAnimation(grid('7-9',3), 0.1)
local leftWalkAnim = rightWalkAnim:clone():flipH()

Player = {}
Player.__index = Player

function Player:new(x, y)
	local object = {
		width        = standImg:getWidth(),
		height       = standImg:getHeight(),
		x            = x,
		y            = y,
		velocityX    = 0,
		velocityY    = 0,
		jumpHeight   = 5 * standImg:getHeight(),
		speed        = 150,
		ySpeed       = 3,
		fallingSpeed = 3,
		life         = 1,
		stateX       = "standingRight",
		stateY       = "standing",
		anim         = nil
	}

	setmetatable(object, self)

	return object
end

function Player:moveLeft()
	if self.stateX ~= "movingLeft" then
		self.velocityX = -self.speed
		self.stateX = "movingLeft"
		self.anim = leftWalkAnim
	end
end

function Player:moveRight()
	if self.stateX ~= "movingRight" then
		self.velocityX = self.speed
		self.stateX = "movingRight"
		self.anim = rightWalkAnim
	end
end

function Player:jump(jumpHeight)
	jumpHeight = jumpHeight or self.jumpHeight

	if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
		self.velocityY = -jumpHeight ---self.jumpHeight
		self.stateY = "jumping" 
	end
end

function Player:dead()
	self.life = 0
	self.velocityX = 0
	self.velocityY = 0
	self.stateX = "dead" 
	self.stateY = "dead"
end

function Player:isColliding(x, y, map)
	local tileX = math.floor(x / tileSize) +1
	local tileY = math.floor(y / tileSize) +1
	
	if tileY > map.height then
		self:dead()
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

function Player:update(dt, map)
	if self.anim then
		self.anim:update(dt)
	end
	
	-- Gravity application
	if self.stateY == "jumping" or self.stateY == "falling" or self.stateY == "jumpFalling" then
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

			if self.anim then
				self.anim:resume()
			end
		else
			if self.stateY == "jumping" then
				self.stateY = "jumpFalling"
			end

			self.y = nextY
		end
	end

	-- Top
	if self.velocityY < 0 then
		if self:isColliding(self.x , nextY, map) 
		or self:isColliding(self.x+self.width -1, nextY, map) then

			self.velocityY = 0
			self.y = nextY + tileSize - nextY % tileSize
		else
			self.y = nextY
		end
	end

	-- Left
	if self.velocityX < 0 then
		if self:isColliding(nextX, self.y, map) 
		or self:isColliding(nextX, self.y+self.height -1, map) then

			self.x = nextX + tileSize - nextX % tileSize
		elseif not self:isColliding(nextX, self.y+self.height, map) then
			if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
				self.stateY = "falling"
				self.anim:pause()
			end

			self.x = nextX
		else
			self.x = nextX
		end
	end

	-- Right
	if self.velocityX > 0 then
		if self:isColliding(nextX+self.width, self.y, map) 
		or self:isColliding(nextX+self.width, self.y+self.height -1, map) then

			self.x = nextX - nextX % tileSize
		elseif not self:isColliding(nextX, self.y+self.height, map) then
			if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
				self.stateY = "falling"
				self.anim:pause()
			end

			self.x = nextX
		else
			self.x = nextX
		end
	end
end

function Player:draw()
	-- Dead
	if self.life == 0 then
		love.graphics.draw(deadImg, self.x, self.y)
	else
		-- Standing
		if self.stateY == "standing" then
			if self.stateX == "standingRight" then
				love.graphics.draw(standImg, self.x, self.y)
			elseif self.stateX == "standingLeft" then
				love.graphics.draw(standImg, self.x, self.y, 0, -1, 1, standImg:getWidth(), 0)
			end
		end

		-- Walking
		if self.stateX == "movingRight" and self.stateY == "standing"
		or self.stateX == "movingLeft" and self.stateY == "standing"
		or self.stateY == "falling"  then

			self.anim:draw(sprites, self.x, self.y)
		end

		-- Jumping
		if self.stateY == "jumping" or self.stateY == "jumpFalling" then
			if self.stateX == "standingRight" or self.stateX == "movingRight" then
				love.graphics.draw(jumpImg, self.x, self.y)
			elseif self.stateX == "standingLeft" or self.stateX == "movingLeft" then
				love.graphics.draw(jumpImg, self.x, self.y, 0, -1, 1, standImg:getWidth(), 0)
			end
		end
	end
end