return function(text)
    Game.client:send(JSON.encode({
        command = "chat",
        uuid = GCSN.uuid,
        message = text
    }).."\n")
end