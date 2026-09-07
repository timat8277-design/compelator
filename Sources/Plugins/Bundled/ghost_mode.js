//@name Режим Призрака (Ghost Mode)
//@version 1.5.0
//@author exteraCommunity
//@description Скрытие статуса прочтения сообщений (нечиталка) и скрытие статуса 'печатает'

extera.log("Плагин 'Режим Призрака' активирован");

// Перехват отправки статуса прочтения сообщений
extera.registerHook("beforeSendReadReceipt", function(chatId, messageId) {
    var ghostEnabled = extera.getSetting("ghost_mode_enabled");
    if (ghostEnabled !== "false") {
        extera.log("👻 Статус прочтения скрыт для сообщения " + messageId);
        // Возврат false блокирует отправку отчета о прочтении на сервер Telegram
        return false;
    }
    return true;
});

// Перехват статуса набора текста ('печатает...')
extera.registerHook("beforeSendTypingStatus", function(chatId) {
    extera.log("👻 Скрыт статус набора текста");
    return false;
});

// Команда переключения
extera.registerCommand("ghost", function(args, chatId) {
    var current = extera.getSetting("ghost_mode_enabled");
    var next = (current === "false") ? "true" : "false";
    extera.setSetting("ghost_mode_enabled", next);
    extera.notify("Режим Призрака", next === "true" ? "👻 Призрак включен (нечиталка активна)" : "👁 Призрак выключен");
});
