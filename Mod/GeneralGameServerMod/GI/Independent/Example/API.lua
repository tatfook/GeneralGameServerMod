

GetGGSAPI():Get("__server_manager__/select", {
    worldId = "1234"
}):Then(function(data)
    echo(data)
end);

