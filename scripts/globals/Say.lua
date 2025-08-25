return function(text)
    Game:sendToServer({
        command = "chat",
        uuid = GCSN.uuid,
        message = text
    })
end