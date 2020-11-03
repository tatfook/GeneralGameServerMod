local TutorialSandbox = gettable("TutorialSandbox");

local function step0()
    TutorialSandbox:GetPage():ShowDialogPage({
        DialogList = {
            {username = "奇仔", text = "你好，我是奇仔，新手城的管理者。欢迎来到主城中心，目前中心还在搭建当中，你可以通过通过编程、动画以及CAD的学习来提升自己的搭建能力，从而成为主城中心的设计师。学习之前，让我们来熟悉一下基础操作吧！"},
        },

        OnClose = function()
            tip("移动位置");
            TutorialSandbox:NextStep();
        end
    });
end

registerClickEvent(function()
    if (TutorialSandbox:GetStep() == 0) then
        step0();
    end
end)

TutorialSandbox:FinishLoadItem("CodeBlock3");