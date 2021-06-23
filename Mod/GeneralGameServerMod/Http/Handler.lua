
--[[
Title: Handler
Author(s):  wxa
Date: 2021-06-23
Desc: Http
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Handler.lua");
------------------------------------------------------------
]]
local Handler = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Handler:Property("HandlerNeuronFile", "Mod/GeneralGameServerMod/Http/Handler.lua");  -- 处理文件

function Handler:OnActivate(msg)
    echo(msg);
    print(msg.msg_type, "-------------------------------")
	--nws.server_log("---------------client request------------")
	-- if type(msg) ~= "table" then
	-- 	return
	-- end

	-- local thread = nil
	-- local url = msg.url
	-- local http = nws.http
	-- local thread_name = __rts__:GetName()

	-- if msg.msg_type == handler.MSG_TYPE_REQUEST_BEGIN then
	-- 	nws.http:handle(msg)

	-- 	NPL.activate("(main)" .. current_dir .. "npl/handler.lua", {
	-- 		msg_type = handler.MSG_TYPE_REQUEST_FINISH,
	-- 		thread_name = __rts__:GetName(),
	-- 	})
	-- elseif msg.msg_type == handler.MSG_TYPE_REQUEST_FINISH then
	-- 	thread_name = msg.thread_name
	-- 	thread = handler.threads[thread_name]
	-- 	thread.msg_count = thread.msg_count - 1
	-- 	--nws.log(thread.thread_name .. " finish request, msg_count:" .. thread.msg_count)
	-- else
	-- 	-- http 请求
	-- 	-- 静态资源 主线程直接处理，可做缓存
	-- 	if http:is_statics(url) then
	-- 		http:handle(msg)
	-- 		return
	-- 	end

	-- 	-- http请求 交由子线程处理 
	-- 	thread = handler:get_thread_by_url(url)
	-- 	thread.msg_count = thread.msg_count + 1
	-- 	msg.msg_type = handler.MSG_TYPE_REQUEST_BEGIN

	-- 	--nws.log(thread.thread_name .. " begin request, msg_count:" .. thread.msg_count)
	-- 	NPL.activate(string.format("(%s)" .. nws.get_nws_path_prefix() .. "npl/handler.lua", thread.thread_name), msg)
	-- end
end


NPL.this(function()
    Handler:OnActivate(msg);
end)
