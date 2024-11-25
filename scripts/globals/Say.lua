return function(text)
    Game.client:send(JSON.encode({
        command = "world",
        subCommand = "chat",
        uuid = GCSN.uuid,
        message = text
    }).."\n")
end