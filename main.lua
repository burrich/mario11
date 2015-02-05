local game, window

function love.load()
	-- Window original size 
	-- Multiply by scale to get the real window size
	window = {
		width = love.graphics.getWidth()/scale,
		height = love.graphics.getHeight()/scale
	}

	game = require "game"
	game.load(window)
end

function love.update(dt)
	game.update(dt, window)
end

function love.draw()
	game.draw(window)

	love.graphics.print("score : " .. game.score, 2, 0)

	if debug then
		love.graphics.print("fps : " .. love.timer.getFPS(), 2, 15)
		love.graphics.print("x : " .. string.format("%.1f", game.player.x), 2, 30)
		love.graphics.print("y : " .. string.format("%.1f", game.player.y), 2, 45)
		love.graphics.print("velocity x : " .. string.format("%.1f", game.player.velocityX), 2, 60)
		love.graphics.print("velocity y : " .. string.format("%.1f", game.player.velocityY), 2, 75)
		love.graphics.print("tile x : " ..  math.floor(game.player.x / tileSize) +1, 2, 90)
		love.graphics.print("tile y : " .. math.floor(game.player.y / tileSize) +1, 2, 105)
		love.graphics.print("state x : " .. game.player.stateX, 2, 120)
		love.graphics.print("state y : " .. game.player.stateY, 2, 135)
		love.graphics.print("life : " .. game.player.life, 2, 150)
	end

	if game.player.life == 0 then
		love.graphics.print("GAME OVER !", window.width/2  * scale - 40, window.height/2 * scale - 20)
	end
end

function love.resize(w, h)
	game.map:resize(w, h)
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.push('quit')
	end
	if key == '`' then
		debug = not debug
	end

	game.keypressed(key)
end

function love.keyreleased(key)
	game.keyreleased(key)
end

function math.clamp(x, min, max)
	return x < min and min or (x > max and max or x)
end