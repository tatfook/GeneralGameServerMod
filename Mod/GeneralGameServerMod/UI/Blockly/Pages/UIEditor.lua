


local Window = GetWindow();
local screenX, screenY, screenWidth, screenHeight = Window:GetScreenPosition();
local PreviewWindowWidth, PreviewWindowHeight = 500, 400;
local PreviewWindowLeft, PreviewWindowTop = screenX + screenWidth - PreviewWindowWidth, screenY + 42;

-- print(PreviewWindowLeft, PreviewWindowTop, PreviewWindowWidth, PreviewWindowHeight)
local PreviewWindow = ShowWindow({}, {url = "%ui%/Blockly/Pages/UIPreview.html", alignment = "_lt", x = PreviewWindowLeft, y = PreviewWindowTop, width = PreviewWindowWidth, height = PreviewWindowHeight});