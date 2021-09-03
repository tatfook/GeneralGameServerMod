
-- local function UpdateScenePosition()
--     local ScreenWidth, ScreenHeight = GetScreenSize();
--     local SceneWidth, SceneHeight = 500, 500;
--     SetSceneMargin(ScreenWidth - SceneWidth, 0, 0, ScreenHeight - SceneHeight);

--     local win = ShowWindow(nil, {
--         template = [[
--     <template style="width: 100%; height: 100%; background-color: #ff0000;">hello world</template>
--         ]],
--         alignment = "_rt",
--         x = -700,
--         y = 100,
--         width= 100,
--         height = 100,
--     });
--     win:SetVisible(false);

--     sleep(3000);
--     win:SetVisible(true);
-- end
-- RegisterScreenSizeChange(UpdateScenePosition);
-- UpdateScenePosition();

