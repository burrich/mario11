scale = 1
debug = false

function love.conf(t)
	t.title = "Platelover"
	t.window.width = 256*scale
	t.window.height = 224*scale
	t.window.resizable = true
	
	if debug then  
		t.console = true
	end
end