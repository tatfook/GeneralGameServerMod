
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

    log_debug("=========================code begin=========================", code, "===========================code end========================");
    self.__co__ = __independent_run__(code_func);
end

function LuaBlocklyEditor:SetConsoleText(text)
    print("AI:SetConsoleText", text);
    if (not self.ConsoleWnd) then return end 
    self.__text__ = text;
    self.ConsoleWnd:GetG().SetText(self.__text__);
end

function LuaBlocklyEditor:AppendConsoleText(text)
    print("AI:AppendConsoleText", text);
    if (not self.ConsoleWnd) then return end 
    self.__text__ = self.__text__ .. Debug.ToString(text);
    self.ConsoleWnd:GetG().SetText(self.__text__);
end

function LuaBlocklyEditor:ShowLuaBlockEditor()
    local AllBlock = {};
    local IsDebug = false;
    local BlocklyEditorWnd = ShowWindow({
        OnClose = function()
            -- self.ConsoleWnd:CloseWindow();
            __debug_close_ui__();
        end,
        OnGenerateBlockCodeAfter = function(block)
            if (not IsDebug or not block:IsStatement()) then return "" end 
            AllBlock[block:GetId()] = block;
            return string.format("__debug_tracker__(%s);\n", block:GetId());
        end,
    }, {
        url = "%gi%/App/AI/UI/BlocklyEditor.html"
    });
    
    local x, y, w, h = BlocklyEditorWnd:GetScreenPosition();
    local width, height = 440, 500;
    __debug_show_ui__({x = x + w - width, y = y + 40, width = width, height = height, draggable = true});
    -- __debug_add_watch_key_value__("key", "hello world");
    -- __debug_add_watch_key_value__("obj", {key = 1});
    -- 执行代码 RunCode
    __debug_start_after_callback__(function(is_debug)
        AllBlock, IsDebug = {}, is_debug;
        local allcode = BlocklyEditorWnd:GetG().GetCode();
        self:RunCode(allcode);
    end);
    -- 追踪器回调
    local curBlockId = nil;
    __debug_tracker_callback__(function(blockId)
        print("-------------__debug_tracker_callback__---------------", blockId)
        curBlockId = blockId;
    end);
    __debug_suspend_before_callback__(function()
        local block = AllBlock[curBlockId];
        if (not block) then return print("--------------__debug_suspend_before_callback__ block not exist-----------", curBlockId) end 
        print("==========__debug_suspend_before_callback__==========", curBlockId)
    end);
    __debug_suspend_after_callback__(function()
        local block = AllBlock[curBlockId];
        if (not block) then return print("--------------__debug_suspend_after_callback__ block not exist-----------", curBlockId) end 
        print("==========__debug_suspend_after_callback__==========", curBlockId)
    end);
    self.BlocklyEditorWnd = BlocklyEditorWnd;
    -- local ConsoleWnd = ShowWindow(nil, {url = "%gi%/App/AI/UI/Console.html", alignment = "_lt", x = x + w - width, y = y + 40, width = width, height = height, draggable = true});
    -- self.ConsoleWnd = ConsoleWnd;
end

-- LuaBlocklyEditor:ShowLuaBlockEditor();