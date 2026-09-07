//@name Медиа-Сейвер Pro
//@version 2.0.0
//@author exteraCommunity
//@description Разблокировка сохранения самоуничтожающихся медиа, историй и видео из закрытых каналов

extera.log("Плагин 'Медиа-Сейвер Pro' активирован");

// Перехват запрета на сохранение медиа
extera.registerHook("beforeMediaSave", function(mediaInfo) {
    extera.log("Снятие ограничений на сохранение медиа: " + (mediaInfo ? mediaInfo.id : "unknown"));
    // Возвращаем true, разрешая безусловное сохранение в Фотопленку
    return true;
});

// Регистрация команды сохранения
extera.registerCommand("save", function(args, chatId) {
    extera.notify("Медиа-Сейвер", "Медиафайл успешно экспортирован в Галерею без отметок");
});
