--[[
	example!
]]


function start()
	registerFunction("start_game",function()
		MessageBoxSimple("start");
	end)
end

function stop()

end

function update()

end


attach({start = start, stop = stop, update = update});
