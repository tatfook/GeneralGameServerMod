
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')

print("-----------------------------")
KeepworkServiceProject:GetProject(71542, function(data, err)
    if not data or
       type(data) ~= 'table' or
       not data.name or
       not data.username or
       not data.world or
       not data.world.commitId then
        return
    end

    GitService:DownloadZIP(data.name, data.username, data.world.commitId, function(bSuccess, downloadPath)
        print("=======================", bSuccess, downloadPath)

        LocalService:MoveZipToFolder('temp/world_temp_download/', downloadPath, function()
            local fileList = LocalService:LoadFiles('temp/world_temp_download/', true, true)

            if not fileList or type(fileList) ~= 'table' or #fileList == 0 then
                return
            end

            echo(fileList, true)

            -- local zipRootPath = ''

            -- if fileList[1] and fileList[1].filesize == 0 then
            --     zipRootPath = fileList[1].filename
            -- end

            -- ParaIO.CreateDirectory(worldpath)

            -- for key, item in ipairs(fileList) do
            --     if key ~= 1 then
            --         local relativePath = commonlib.Encoding.Utf8ToDefault(item.filename:gsub(zipRootPath .. '/', ''))

            --         if item.filesize == 0 then
            --             local folderPath = worldpath .. relativePath .. '/'

            --             ParaIO.CreateDirectory(folderPath)
            --         else
            --             local filePath = worldpath .. relativePath

            --             ParaIO.MoveFile(item.file_path, filePath)
            --         end
            --     end
            -- end

            -- ParaIO.DeleteFile('temp/world_temp_download/')

            -- if callback and type(callback) then
            --     callback()
            -- end
        end)
    end)
end)

-- temp/world_temp_download/lixizhi_world_GGSDemo
-- local directory = ParaWorld.GetWorldDirectory() .. "blockWorld.lastsave"
-- print(directory)
-- for filename in lfs.dir(directory) do
--     print(filename)
-- end