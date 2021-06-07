function main()
    print("main exec"); 
end

function clear()
    print("clear exec");
end

RegisterEventCallBack(EventType.KEY_DOWN, function(event)
    echo(event)
end)

RegisterEventCallBack(EventType.MOUSE_DOWN, function(event)
    echo(event)
end)