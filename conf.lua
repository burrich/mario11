scale = 2
debug = false

function love.conf(t)
	t.title = "Platelover"
	t.window.width = 256*scale
	t.window.height = 224*scale
	
	if debug then  
		t.console = true
		t.window.resizable = true
	end
end