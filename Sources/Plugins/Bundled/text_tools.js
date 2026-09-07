//@name Текстовые Утилиты (TextTools)
//@version 1.1.0
//@author exteraCommunity
//@description Быстрые команды: .shrug, .calc, .time, .reverse, .spoiler

extera.log("Плагин 'Текстовые Утилиты' загружен");

// Команда .shrug -> ¯\_(ツ)_/¯
extera.registerCommand("shrug", function(args, chatId) {
    var prefix = args.length > 0 ? args.join(" ") + " " : "";
    extera.sendMessage(chatId, prefix + "¯\\_(ツ)_/¯");
});

// Команда .calc 2+2*2
extera.registerCommand("calc", function(args, chatId) {
    if (!args || args.length === 0) {
        extera.notify("Калькулятор", "Использование: .calc <выражение>");
        return;
    }
    var expr = args.join("");
    try {
        var res = eval(expr);
        extera.sendMessage(chatId, "🧮 " + expr + " = " + res);
    } catch(e) {
        extera.notify("Калькулятор", "Ошибка выражения: " + e);
    }
});

// Команда .time -> текущее время
extera.registerCommand("time", function(args, chatId) {
    var d = new Date();
    var timeStr = d.toLocaleTimeString();
    extera.sendMessage(chatId, "⏰ Текущее время: " + timeStr);
});
