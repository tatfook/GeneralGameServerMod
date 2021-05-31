

WindowSize = "500X400";
WindowSizeOptions = {
    "500X400",
    "1200X900",
}
TemplateCode = "";

function _G.SetTemplateCode(code)
    TemplateCode = code;
end

function OnWindowSizeChange(value)
    local width, height = string.match(value, "(%d+)X(%d+)");
    if (type(_G.OnWindowSizeChange) == "function") then
        _G.OnWindowSizeChange(tonumber(width), tonumber(height));
    end
end
