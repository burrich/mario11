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

Player.width        = 0
Player.height       = 0
Player.x            = 0
Player.y            = 0
Player.velocityX    = 0
Player.velocityY    = 0
Player.jumpHeight   = 0
Player.speed        = 150
Player.ySpeed       = 3
Player.fallingSpeed = 3
Player.life         = 3
Player.stateX       = "standingRight"
Player.stateY       = "standing"

function Player:new()
	object = {}

	setmetatable(object, self)
	self.__index    = self
	self.width      = tileSize
	self.height     = tileSize
	self.x          = windowWidth/2 -- - Player.width/2
	self.y          = world.ground - tileSize
	self.jumpHeight = 5*tileSize

	return object
end

function Player:moveLeft()
	self.velocityX = -self.speed
	self.stateX = "movingLeft"
end

function Player:moveRight()
	self.velocityX = self.speed
	self.stateX = "movingRight"
end

function Player:jump()
	if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
		self.velocityY = -self.jumpHeight
		self.stateY = "jumping" 
	end
end

function Player:isColliding(x, y)
	local tileX = math.floor(x / tileSize) +1
	local tileY = math.floor(y / tileSize) +1
	
	if tileY > map.height then
		self.life = 0
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

function Player:update(dt)
	-- Animations update
	leftWalkAnim:update(dt)
	rightWalkAnim:update(dt)
	
	-- Gravity application
	if self.stateY == "jumping" or self.stateY == "falling" or self.stateY == "jumpFalling" then
		self.velocityY = self.velocityY + world.gravity*dt*self.ySpeed
	end

	local nextX = self.x + self.velocityX*dt
	local nextY = self.y + self.velocityY*dt*self.ySpeed

	-- Bottom
	if self.velocityY > 0 then
		if self:isColliding(self.x , nextY+self.height) 
		or self:isColliding(self.x+self.width -1, nextY+self.height) then

			self.stateY = "standing"
			self.velocityY = 0
			self.y = nextY - nextY % tileSize

			if self.stateX == "standingLeft" or self.stateX == "movingLeft" then
				leftWalkAnim:resume()
			else 
				rightWalkAnim:resume()
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
		elseif not self:isColliding(nextX, self.y+self.height) then
			if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
				self.stateY = "falling"
				leftWalkAnim:pause()
			end

			self.x = nextX
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
			if self.stateY ~= "jumping" and self.stateY ~= "jumpFalling" then
				self.stateY = "falling"
				rightWalkAnim:pause()
			end

			self.x = nextX
		else
			self.x = nextX
		end
	end
end

function Player:draw()
	-- love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	-- If dead
	if self.life == 0 then
		love.graphics.draw(deadImg, self.x, self.y)
	else
		-- If standing
		if self.stateY == "standing" then
			if self.stateX == "standingRight" then
				love.graphics.draw(standImg, self.x, self.y)
			elseif self.stateX == "standingLeft" then
				love.graphics.draw(standImg, self.x, self.y, 0, -1, 1, standImg:getWidth(), 0)
			end
		end

		-- If walking
		if self.stateX == "movingRight" and self.stateY == "standing"
		or self.stateY == "falling" and (self.stateX == "movingRight" or self.stateX == "standingRight") then

			rightWalkAnim:draw(sprites, self.x, self.y)

		elseif self.stateX == "movingLeft" and self.stateY == "standing"
		or self.stateY == "falling" and (self.stateX == "movingLeft" or self.stateX == "standingLeft") then
			
			leftWalkAnim:draw(sprites, self.x, self.y)
		end

		-- If jumping
		if self.stateY == "jumping" or self.stateY == "jumpFalling" then
			if self.stateX == "standingRight" or self.stateX == "movingRight" then
				love.graphics.draw(jumpImg, self.x, self.y)
			elseif self.stateX == "standingLeft" or self.stateX == "movingLeft" then
				love.graphics.draw(jumpImg, self.x, self.y, 0, -1, 1, standImg:getWidth(), 0)
			end
		end
	end
end