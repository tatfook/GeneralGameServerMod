
# GGS 服务端

服务端程序逻辑主要是对客户单发送过来的数据进行处理和返回. GGS Core 通过配置数据处理脚本来自定义业务层的数据处理逻辑.

## 使用流程

1. 在配置文件中引入如下配置:

    ```xml
    <!-- GGS 后端配置 -->
    <GeneralGameServer>
        ...
        <!-- filename: 数据处理脚本 文件名必须为NPL.load支持的路径 -->
        <DataHandler
            filename="Mod/GeneralGameServerMod/App/Server/AppServerDataHandler.lua">
        </DataHandler>
        ...
    </GeneralGameServer>
    ```

2. 数据处理内容形式如下:

    ```lua
    -- 数据处理基类
    local ServerDataHandler = NPL.load("Mod/GeneralGameServerMod/Core/Server/ServerDataHandler.lua");

    -- 数据处理导出类
    local AppServerDataHandler = commonlib.inherit(ServerDataHandler, NPL.export());

    -- 收到数据处理函数
    function AppServerDataHandler:RecvData(data)
        -- 发送数据给当前用户
        if (data == "player") then 
            self:SendData("hello player");
        end

        -- 发送数据给所有在线用户  第二个参数 true: 接收者包含当前用户  false: 接收者不包含当前用户
        if (data == "all player") then
            self:SendDataToAllPlayer("hello all player", false);
        end
    end
    ```

3. 客户端也可以有对应数据处理脚本文件, 具体使用方式参考客户端的 readme.md 内容形式如下:

    ```lua
    NPL.load("Mod/GeneralGameServerMod/Core/Client/ClientDataHandler.lua");

    local AppClientDataHandler = commonlib.inherit(commonlib.gettable("Mod.GeneralGameServerMod.Core.Client.ClientDataHandler"), NPL.export());

    function AppClientDataHandler:RecvData(data)
        -- self:SendData("发送数据给服务器");
    end
    ```
