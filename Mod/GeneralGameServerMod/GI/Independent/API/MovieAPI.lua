NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");

local MovieAPI = NPL.export();

setmetatable(MovieAPI, {__call = function(_, CodeEnv)
    local all_movies = {};

    CodeEnv.MovieManager = MovieManager;
    
    CodeEnv.__SetMovie__ = function(name, bx, by, bz)
        local channel = MovieManager:CreateGetMovieChannel(name);
        channel:SetStartBlockPosition(math.floor(bx),math.floor(by),math.floor(bz));
        all_movies[name] = channel;
        return channel;
    end

    CodeEnv.__PlayMovie__ = function(name, timeFrom, timeTo, bLoop, callback)
        if (not name or not all_movies[name]) then return end 
        local channel = MovieManager:CreateGetMovieChannel(name);
        if(bLoop) then
            channel:PlayLooped(timeFrom, timeTo);
        else
            channel:Play(timeFrom, timeTo);
        end

        if (type(callback) == "function") then
            channel:Connect("finished", callback);
        end
    end

	CodeEnv.__StopMovie__ = function(name)
        if (not name or not all_movies[name]) then return end 
        all_movies[name] = nil;
        MovieManager:CreateGetMovieChannel(name):Stop();
    end

    CodeEnv.__GetMovieTime__ = function(name)
        if (not name or not all_movies[name]) then return 0 end 
        local channel = MovieManager:CreateGetMovieChannel(name);
	    local movieClip = channel:CreateGetStartMovieClip()
        return movieClip and movieClip:GetLength() or 0;
    end

    CodeEnv.RegisterEventCallBack(CodeEnv.EventType.CLEAR, function() 
        for _, channel in pairs(all_movies) do
            channel:Stop();
        end
    end);
end});