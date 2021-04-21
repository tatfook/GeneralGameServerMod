

local AllCategoryMap, AllBlockMap = {}, {};

AllCategoryList, AllBlockList = {}, {};
NewCategoryName, NewCategoryColor = "", "";

function ClickNewCategoryBtn()
    if (NewCategoryName == "" or AllCategoryMap[NewCategoryName]) then return end 
    
    AllCategoryMap[NewCategoryName] = {
        name = NewCategoryName,
        color = NewCategoryColor,
    }

    table.insert(AllCategoryList, AllCategoryMap[NewCategoryName]);
    NewCategoryName, NewCategoryColor = "", "";
end

function ClickDeleteCategoryBtn(categoryName)
    AllCategoryMap[categoryName] = nil;
    for i, category in ipairs(AllCategoryList) do 
        if (category.name == categoryName) then
            table.remove(AllCategoryList, i);
        end
    end
end
