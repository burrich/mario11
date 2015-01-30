Player = {}

Player.width        = 0
Player.height       = 0
Player.x            = 0
Player.y            = 0
Player.velocityX    = 0
Player.velocityY    = 0
Player.jumpHeight   = 0
Player.ySpeed       = 3
Player.fallingSpeed = 3
Player.speed        = 150
Player.stateX       = "standing"
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
	if self.stateY ~= "jumping" then
		self.velocityY = -self.jumpHeight
		self.stateY = "jumping" 
	end
end

function Player:stop()
	player.velocityX = 0
	player.stateX = "standing"
end

function Player:isColliding(x, y)
	local tileX = math.floor(x / tileSize) +1
	local tileY = math.floor(y / tileSize) +1

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
	if self.stateY == "jumping" or self.stateY == "falling" then
		self.velocityY = self.velocityY + world.gravity*dt*self.ySpeed
	end

	nextX = self.x + self.velocityX*dt
	nextY = self.y + self.velocityY*dt*self.ySpeed

	-- Bottom
	if self.velocityY > 0 then
		if self:isColliding(self.x , nextY+self.height) 
		or self:isColliding(self.x+self.width -1, nextY+self.height) then

			self.stateY = "standing"
			self.velocityY = 0
			self.y = nextY - nextY % tileSize
		else
			self.stateY = "falling"
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
			if self.stateY ~= "jumping" then
				self.stateY = "falling"
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
			if self.stateY ~= "jumping" then
				self.stateY = "falling"
			end

			self.x = nextX
		else
			self.x = nextX
		end
	end
end

function Player:draw()
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end