

local LuaBlocklyEditor = module();

function LuaBlocklyEditor:RunCode(code)
    if (self.__co__) then
        __coroutine_exit_all__(self.__co__, true);
    end

    local G = setmetatable({}, {__index = _G});
    local code_func, err_info = loadstring(code, "AI:RunCode");
    if (not code_func) then 
        self:AppendConsoleText("=========================代码编译失败=======================");
        self:AppendConsoleText(code);
        self:AppendConsoleText(err_info);
        return ; 
    end

    setfenv(code_func, G);
    self.__text__ = "";
    G.print = function(...)
        self:AppendConsoleText(...);
    end

    self.__co__ = __independent_run__(code_func);
end

function LuaBlocklyEditor:SetConsoleText(text)
    print("AI:SetConsoleText", text);
    self.__text__ = text;
    self.ConsoleWnd:GetG().SetText(self.__text__);
end

function LuaBlocklyEditor:AppendConsoleText(text)
    print("AI:AppendConsoleText", text);
    self.__text__ = self.__text__ .. Debug.ToString(text);
    self.ConsoleWnd:GetG().SetText(self.__text__);
end

function LuaBlocklyEditor:ShowLuaBlockEditor()
    local BlocklyEditorWnd = ShowWindow({
        OnClose = function()
            self.ConsoleWnd:CloseWindow();
        end,
        OnRun = function(code)
            self:RunCode(code);
        end,
    }, {
        url = "%gi%/App/AI/UI/BlocklyEditor.html"
    });
    
    local x, y, w, h = BlocklyEditorWnd:GetScreenPosition();
    local width, height = 500, 400;
    local ConsoleWnd = ShowWindow(nil, {url = "%gi%/App/AI/UI/Console.html", alignment = "_lt", x = x + w - width, y = y + 40, width = width, height = height, draggable = true});

    self.BlocklyEditorWnd = BlocklyEditorWnd;
    self.ConsoleWnd = ConsoleWnd;
end

-- LuaBlocklyEditor:ShowLuaBlockEditor();