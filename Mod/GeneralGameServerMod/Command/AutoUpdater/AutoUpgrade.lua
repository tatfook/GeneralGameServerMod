
local lfs = luaopen_lfs();

local function GetPlatform()
    local platform = ParaEngine.GetAttributeObject():GetField("Platform", 0);
    if(platform == 3) then
        return "win32";
    elseif(platform == 1) then
        return "ios";
    elseif(platform == 2) then
        return "android";
    elseif(platform == 5) then
        return "linux";
    elseif(platform == 8) then
        return "mac";
    elseif(platform == 13) then
        return "wp8";
    elseif(platform == 14) then
        return "winrt";
    elseif(platform == 0) then
        return "unknown";
    end
end

local function ToCanonicalFilePath(filename, platform)
    platform = platform or GetPlatform();

	if(platform == "win32") then
        filename = string.gsub(filename, "/+", "\\");
		filename = string.gsub(filename, "\\+", "\\");
	else
		filename = string.gsub(filename, "\\+", "/");
        filename = string.gsub(filename, "/+", "/");
	end
	
    return filename;
end

local function decompress(sourceFileName, destFileName)
    if(not sourceFileName or not destFileName)then return end
    local file = ParaIO.open(sourceFileName,"r");
    if(file:IsValid())then
        local content = file:GetText(0,-1);
        local dataIO = {content = content, method = "gzip"};
        if(NPL.Decompress(dataIO)) then
            if(dataIO and dataIO.result)then
                ParaIO.CreateDirectory(destFileName);
				local file = ParaIO.open(destFileName, "w");
				if(file:IsValid()) then
					file:write(dataIO.result,#dataIO.result);
					file:close();
				end
                return true
            end
		end
    end
    return false;
end

-- 拷贝目录
local auto_upgrade_failed = false;
local function CopyDirectory(src_dir, dst_dir, recursive)
    src_dir = ToCanonicalFilePath(src_dir .. "/");
    dst_dir = ToCanonicalFilePath(dst_dir .. "/");
    ParaIO.CreateDirectory(dst_dir);
    for filename in lfs.dir(src_dir) do
        if (filename ~= "." and filename ~= "..") then
            local src_file = ToCanonicalFilePath(src_dir .. "/" .. filename);
            local dst_file = ToCanonicalFilePath(dst_dir .. "/" .. filename);
            local fileattr = lfs.attributes(src_file);
            if (fileattr.mode == "directory") then
                if (recursive) then CopyDirectory(src_file, dst_file, recursive) end
            else
                if (string.match(dst_file, "%.p$")) then 
                    dst_file = string.gsub(dst_file, "%.p$", "");
                    if (not decompress(src_file, dst_file)) then
                        print(string.format("file decompress failed: %s => %s", src_file, dst_file));
                        auto_upgrade_failed = true;
                    else 
                        print(string.format("file decompress: %s => %s", src_file, dst_file));
                    end
                end
               
                -- if (not ParaIO.CopyFile(src_file, dst_file, true)) then
                --     print(string.format("file copy failed: %s => %s", src_file, dst_file));
                --     auto_upgrade_failed = true;
                -- end
            end
        end
    end
end

local install_directory = ParaEngine.GetAppCommandLineByParam("install_directory", "");
install_directory = install_directory ~= "" and install_directory or ParaIO.GetWritablePath();
local latest_directory = ParaEngine.GetAppCommandLineByParam("latest_directory", "");
latest_directory = latest_directory ~= "" and latest_directory or ToCanonicalFilePath(ParaIO.GetWritablePath() .. "/caches/latest");

print("==========================auto upgrade begin=========================");
print("latest directoty:", latest_directory);
print("install directoty:", install_directory);
CopyDirectory(ToCanonicalFilePath(latest_directory), ToCanonicalFilePath(install_directory), true);

if (not auto_upgrade_failed) then
    ParaGlobal.ShellExecute("open", ToCanonicalFilePath(install_directory .. [[\ParaEngineClient.exe]]), [[mc=true]], "", 1);
end

print("==========================auto upgrade end=========================");
ParaGlobal.Exit(0);

-- print(ParaIO.CopyFile([[D:\ParacraftDev\caches\latest\mian.pkg]], [[D:\ParacraftDev\mian.pkg]], true))


