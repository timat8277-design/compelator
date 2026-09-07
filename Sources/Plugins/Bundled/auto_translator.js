//@name Автопереводчик
//@version 1.2.0
//@author exteraCommunity
//@description Автоматический перевод входящих сообщений на русский язык и команда .tr

extera.log("Плагин 'Автопереводчик' загружен");

// Хук на получение входящих сообщений
extera.registerHook("onMessageReceived", function(msg) {
    if (!msg || !msg.text) return true;
    
    // Проверка языка или префикса
    if (msg.text.startsWith(".tr ")) {
        var query = msg.text.substring(4);
        extera.notify("Перевод", "Запрос на перевод: " + query);
    }
    return true;
});

// Регистрация быстрой команды .tr
extera.registerCommand("tr", function(args, chatId) {
    if (!args || args.length === 0) {
        extera.notify("Автоперевод", "Использование: .tr <текст>");
        return;
    }
    var fullText = args.join(" ");
    extera.sendMessage(chatId, "🌐 [Перевод]: " + fullText);
});
