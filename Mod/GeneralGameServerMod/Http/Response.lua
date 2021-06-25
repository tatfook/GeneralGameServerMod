--[[
Title: Response
Author(s):  wxa
Date: 2021-06-23
Desc: Response
use the lib:
------------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/Http/Response.lua");
------------------------------------------------------------
]]

local Util = NPL.load("./Util.lua");
local MimeType = NPL.load("./MimeType.lua");

local Response = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local status_strings = {
    ['200'] ="HTTP/1.1 200 OK\r\n",
    ['201'] ="HTTP/1.1 201 Created\r\n",
    ['202'] ="HTTP/1.1 202 Accepted\r\n",
    ['204'] = "HTTP/1.1 204 No Content\r\n",
    ['300'] = "HTTP/1.1 300 Multiple Choices\r\n",
    ['301'] = "HTTP/1.1 301 Moved Permanently\r\n",
    ['302'] = "HTTP/1.1 302 Moved Temporarily\r\n",
    ['304'] = "HTTP/1.1 304 Not Modified\r\n",
    ['400'] = "HTTP/1.1 400 Bad Request\r\n",
    ['404'] = "HTTP/1.1 401 Unauthorized\r\n",
    ['403'] = "HTTP/1.1 403 Forbidden\r\n",
    ['404'] = "HTTP/1.1 404 Not Found\r\n",
    ['500'] = "HTTP/1.1 500 Internal Server Error\r\n",
    ['501'] = "HTTP/1.1 501 Not Implemented\r\n",
    ['502'] = "HTTP/1.1 502 Bad Gateway\r\n",
    ['503'] = "HTTP/1.1 503 Service Unavailable\r\n",
}

Response:Property("StatusCode", 200);
Response:Property("Charset", "utf-8");
Response:Property("ContentType", MimeType.html);
Response:Property("Content", "");
Response:Property("Finished", false, "IsFinished");
Response:Property("Headers");
Response:Property("Cookies");
Response:Property("Request");

function Response:ctor()
end

function Response:Init(request)
	self:SetFinished(false);
	self:SetRequest(request);
	self:SetHeaders({});
	self:SetCookies({});

	return self;
end

-- 获取连接ID
function Response:GetNid()
	return self:GetRequest():GetNid();
end

-- 重定向
function response:Redirect(url)
	self:SetStatusCode(302);
	self:SetHeader('Location', url);
	self:Send();
end

-- 发送内容
function Response:Send(content, status_code)
	if (self:IsFinished()) then return end 

	status_code = tostring(status_code or self:GetStatusCode() or 200);
	content = content == nil and self:GetContent() or content;

	if(type(content) == 'table') then
		self:SetContentType(MimeType.json)
		content = Util:ToJson(content)
	else
		content = tostring(content or "")
	end

	local out = {};
	local header_format = "%s: %s\r\n";
	-- status code
    out[#out + 1] = status_strings[status_code];
	-- content-type
	out[#out + 1] = string.format(header_format, "Content-Type", (self:GetContentType() or MimeType.html) .. " charset=" .. (self:GetCharset() or "utf-8"));
	-- content-length
	out[#out + 1] = string.format(header_format, "Content-Length", #content);
    -- other header
	for name, value in pairs(self:GetHeaders()) do
        out[#out+1] = string.format(header_format, name, value);
    end
	-- cookies header
	for _, cookie in ipairs(self:GetCookies()) do
		out[#out + 1] = cookie:toString();
	end
	-- content wrap line
    out[#out+1] = "\r\n"
	-- content
    out[#out+1] = content;

	self:SetFinished(true);

    NPL.activate(format("%s:http", self.request.nid), table.concat(out))
end

-- 设置响应头
function Response:SetHeader(key, val)
	self:GetHeaders()[key] = val;
end

-- 设置内容类型通过扩展名
function Response:SetContentTypeByExt(ext) 
	self:SetContentType(MimeType[ext]);
end

-- 添加Cookie
function Response:AppendCookie(cookie)
	local cookies = self:GetCookies();
	cookies[#(cookies) + 1] = cookie;
end

-- 发送文件
function Response:SendFile(path, ext)
	if (not path or path == "") then return self:Send() end

	path = string.match(path, '([^?]*)');
	path = string.gsub(path, '//', '/');
	ext = ext or path:match('^.+%.([a-zA-Z0-9]+)$');

	local file = io.open(path, "rb");
	if (not file) then return self:Send("文件不存在:" .. path, 404)	end

	local content = file:read("*a");
	file:close();

	self:SetContentTypeByExt(ext);
	self:Send(content)
end



