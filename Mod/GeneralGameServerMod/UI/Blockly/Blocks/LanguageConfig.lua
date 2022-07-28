

local LanguageConfig = NPL.export();
local ToolBoxXmlText = NPL.load("./ToolBoxXmlText.lua");

local __language_name_map__ = {
    [""] = "npl", ["npl"] = "npl",
    ["npl_junior"] = "npl_junior",
    ["mcml"] = "mcml", ["html"] = "mcml",
    ["old_cad"] = "cad", ["old_npl_cad"] = "cad",
    ["npl_cad"] = "cad", ["cad"] = "cad", 
    ["game_inventor"] = "game_inventor",
}
function LanguageConfig.GetLanguageName(lang)
    return __language_name_map__[lang] or "npl"
end

local __language_type_map__ = {
    ["npl"] = "npl",
    ["mcml"] = "html" ,
}
function LanguageConfig.GetLanguageType(lang_name)
    return __language_type_map__[lang_name] or "npl";
end

local __language_version_map__ = {
    ["npl"] = "1.0.0",
    ["cad"] = "1.0.0",
    ["npl_junior"] = "1.0.0",
}

function LanguageConfig.GetVersion(lang_name)
    return __language_version_map__[lang_name] or "0.0.0"; 
end

function LanguageConfig.IsSupportScratch(lang)
    local lang_name = LanguageConfig.GetLanguageName(lang);
    return lang_name == "npl" or lang_name == "cad" or lang_name == "npl_junior" or lang_name == "mcml" or lang_name == "game_inventor";
end

function LanguageConfig.GetToolBoxXmlText(lang, version)
    local lang_name = LanguageConfig.GetLanguageName(lang);
    return ToolBoxXmlText.GetXmlText(lang, version);
end