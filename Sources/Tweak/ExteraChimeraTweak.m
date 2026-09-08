//
//  ExteraChimeraTweak.m
//  Твик для инъекции в Telegram 12.9.2:
//  1. Плавающая кнопка «👑 Chimera» на экране и кнопка в Настройках Telegram.
//  2. Локальная накрутка баланса Telegram Stars (Звёзды) и токенов GRAM / TON.
//  3. Бесконечная локальная выдача любых NFT подарков с кастомными фонами, узорами и номерами.
//  4. Бесконечная локальная генерация коллекционных @Username (Fragment NFT) и анонимных +888 номеров.
//  5. Функция надевания подарка (Wear Gift) в шапку профиля и чатов.
//  6. Локальный Telegram Premium (isPremium = YES).
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define CHIMERA_STORAGE_KEY @"chimeranft_master_storage_v3"
#define CHIMERA_BTN_TAG 77702
#define CHIMERA_FLOATING_TAG 77703

#pragma mark - Хранилище ChimeraStore

@interface ChimeraStore : NSObject
+ (instancetype)shared;
@property (nonatomic, assign) long long starsBalance;
@property (nonatomic, assign) double gramBalance;
@property (nonatomic, assign) double tonBalance;
@property (nonatomic, strong) NSMutableArray<NSString *> *usernames;
@property (nonatomic, assign) NSInteger activeUsernameIndex;
@property (nonatomic, strong) NSMutableArray<NSString *> *numbers;
@property (nonatomic, assign) NSInteger activeNumberIndex;
@property (nonatomic, assign) NSInteger ratingScore;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *gifts;
@property (nonatomic, assign) NSInteger activeWornGiftIndex;

- (NSString *)currentUsername;
- (NSString *)currentNumber;
- (NSDictionary *)currentWornGift;
- (void)save;
- (void)load;
@end

@implementation ChimeraStore

+ (instancetype)shared {
    static ChimeraStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[ChimeraStore alloc] init];
        [store load];
    });
    return store;
}

- (void)load {
    NSDictionary *data = [[NSUserDefaults standardUserDefaults] objectForKey:CHIMERA_STORAGE_KEY];
    if (data) {
        self.starsBalance = [data[@"stars"] longLongValue];
        self.gramBalance = [data[@"gram"] doubleValue];
        self.tonBalance = [data[@"ton"] doubleValue];
        self.usernames = [NSMutableArray arrayWithArray:data[@"usernames"] ?: @[@"chimera", @"durov", @"ton_holder"]];
        self.activeUsernameIndex = [data[@"active_user_idx"] integerValue];
        self.numbers = [NSMutableArray arrayWithArray:data[@"numbers"] ?: @[@"+888 0123 4567", @"+888 7777 7777", @"+888 8888 8888"]];
        self.activeNumberIndex = [data[@"active_num_idx"] integerValue];
        self.ratingScore = [data[@"rating"] integerValue] ?: 9999;
        self.activeWornGiftIndex = [data[@"active_gift_idx"] integerValue];

        NSArray *rawGifts = data[@"gifts"];
        if (rawGifts.count > 0) {
            self.gifts = [NSMutableArray array];
            for (NSDictionary *g in rawGifts) {
                [self.gifts addObject:[g mutableCopy]];
            }
        } else {
            [self setupDefaultGifts];
        }
    } else {
        self.starsBalance = 777777;
        self.gramBalance = 1000.0;
        self.tonBalance = 250.0;
        self.usernames = [NSMutableArray arrayWithArray:@[@"chimera", @"durov", @"nft_king", @"ton_whale"]];
        self.activeUsernameIndex = 0;
        self.numbers = [NSMutableArray arrayWithArray:@[@"+888 0123 4567", @"+888 7777 7777", @"+888 8888 8888"]];
        self.activeNumberIndex = 0;
        self.ratingScore = 9999;
        self.activeWornGiftIndex = 0;
        [self setupDefaultGifts];
        [self save];
    }
}

- (void)setupDefaultGifts {
    self.gifts = [NSMutableArray arrayWithArray:@[
        [@{
            @"title": @"Durov's Cap",
            @"number": @1,
            @"model": @"cap",
            @"backdrop": @"Неон / Космос (#1F2338)",
            @"pattern": @"Золотые Звёзды (Gold Stars)",
            @"rarity": @"Unique (1 of 1)",
            @"isWorn": @YES
        } mutableCopy],
        [@{
            @"title": @"King Pepe",
            @"number": @777,
            @"model": @"pepe",
            @"backdrop": @"Изумрудный Блеск (#152F24)",
            @"pattern": @"Короны (Crowns)",
            @"rarity": @"Legendary",
            @"isWorn": @NO
        } mutableCopy],
        [@{
            @"title": @"Gram Diamond",
            @"number": @108,
            @"model": @"gem",
            @"backdrop": @"Тёмный Сапфир (#1B2A4A)",
            @"pattern": @"Кристаллы (Cyan Crystals)",
            @"rarity": @"Mythic",
            @"isWorn": @NO
        } mutableCopy]
    ]];
}

- (NSString *)currentUsername {
    if (self.activeUsernameIndex >= 0 && self.activeUsernameIndex < (NSInteger)self.usernames.count) {
        return self.usernames[self.activeUsernameIndex];
    }
    return @"chimera";
}

- (NSString *)currentNumber {
    if (self.activeNumberIndex >= 0 && self.activeNumberIndex < (NSInteger)self.numbers.count) {
        return self.numbers[self.activeNumberIndex];
    }
    return @"+888 0123 4567";
}

- (NSDictionary *)currentWornGift {
    if (self.activeWornGiftIndex >= 0 && self.activeWornGiftIndex < (NSInteger)self.gifts.count) {
        return self.gifts[self.activeWornGiftIndex];
    }
    return self.gifts.firstObject;
}

- (void)save {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"stars"] = @(self.starsBalance);
    dict[@"gram"] = @(self.gramBalance);
    dict[@"ton"] = @(self.tonBalance);
    dict[@"usernames"] = self.usernames;
    dict[@"active_user_idx"] = @(self.activeUsernameIndex);
    dict[@"numbers"] = self.numbers;
    dict[@"active_num_idx"] = @(self.activeNumberIndex);
    dict[@"rating"] = @(self.ratingScore);
    dict[@"active_gift_idx"] = @(self.activeWornGiftIndex);
    dict[@"gifts"] = self.gifts;

    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:CHIMERA_STORAGE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

#pragma mark - Экран управления Chimera NFT (ChimeraNFTSettingsViewController)

@interface ChimeraNFTSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ChimeraNFTSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Chimera NFT";
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.12 alpha:1.0];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Готово" style:UIBarButtonItemStyleDone target:self action:@selector(closeTapped)];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.12 alpha:1.0];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [self setupHeaderCard];
}

- (void)setupHeaderCard {
    ChimeraStore *s = [ChimeraStore shared];
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 160)];

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16, 10, self.view.bounds.size.width - 32, 140)];
    card.backgroundColor = [UIColor colorWithRed:0.11 green:0.14 blue:0.20 alpha:0.95];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1.2;
    card.layer.borderColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:0.6].CGColor;
    [header addSubview:card];

    UILabel *badge = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, card.bounds.size.width - 32, 18)];
    badge.text = @"👑 CHIMERA NFT • ⭐ LOCAL PREMIUM";
    badge.font = [UIFont boldSystemFontOfSize:11];
    badge.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
    [card addSubview:badge];

    UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, card.bounds.size.width - 32, 28)];
    userLabel.text = [NSString stringWithFormat:@"@%@", [s currentUsername]];
    userLabel.font = [UIFont boldSystemFontOfSize:22];
    userLabel.textColor = [UIColor whiteColor];
    [card addSubview:userLabel];

    UILabel *numLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 62, card.bounds.size.width - 32, 18)];
    numLabel.text = [NSString stringWithFormat:@"📞 %@   •   🏆 Рейтинг: %ld pts", [s currentNumber], (long)s.ratingScore];
    numLabel.font = [UIFont systemFontOfSize:12];
    numLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    [card addSubview:numLabel];

    NSDictionary *worn = [s currentWornGift];
    UILabel *wornLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 84, card.bounds.size.width - 32, 18)];
    wornLabel.text = [NSString stringWithFormat:@"🎁 Надет: %@ #%@  [Узор: %@]", worn[@"title"] ?: @"None", worn[@"number"] ?: @(1), worn[@"pattern"] ?: @"Звёзды"];
    wornLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    wornLabel.textColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0];
    [card addSubview:wornLabel];

    UILabel *balLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 108, card.bounds.size.width - 32, 20)];
    balLabel.text = [NSString stringWithFormat:@"⭐️ %lld Stars   💎 %.1f GRAM   🔷 %.1f TON", s.starsBalance, s.gramBalance, s.tonBalance];
    balLabel.font = [UIFont boldSystemFontOfSize:12];
    balLabel.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:0.5 alpha:1.0];
    [card addSubview:balLabel];

    self.tableView.tableHeaderView = header;
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView DataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"⭐️ НАКРУТКА БАЛАНСА (ЛОКАЛЬНО)";
        case 1: return @"🎁 КОЛЛЕКЦИЯ И ВЫДАЧА NFT ПОДАРКОВ";
        case 2: return @"🏷️ COLLECTIBLE @USERNAME (БЕСКОНЕЧНО)";
        case 3: return @"📞 АНОНИМНЫЕ +888 НОМЕРА (БЕСКОНЕЧНО)";
        default: return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    ChimeraStore *s = [ChimeraStore shared];
    switch (section) {
        case 0: return 3;
        case 1: return 1 + s.gifts.count;
        case 2: return 1 + s.usernames.count;
        case 3: return 1 + s.numbers.count;
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChimeraStore *s = [ChimeraStore shared];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChimeraCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ChimeraCell"];
    }
    cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.14 blue:0.20 alpha:0.95];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"⭐️ Telegram Stars (Звёзды)";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lld ⭐️ (Нажмите для накрутки)", s.starsBalance];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"💎 Баланс GRAM";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f GRAM (Нажмите для накрутки)", s.gramBalance];
        } else {
            cell.textLabel.text = @"🔷 Баланс TON";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f TON (Нажмите для накрутки)", s.tonBalance];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"➕ Выдать себе новый NFT подарок";
            cell.detailTextLabel.text = @"Выбор любого узора, фона, номера и модели";
            cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
        } else {
            NSInteger idx = indexPath.row - 1;
            NSDictionary *gift = s.gifts[idx];
            BOOL isWorn = (idx == s.activeWornGiftIndex);
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ #%@ %@", isWorn ? @"👑" : @"🎁", gift[@"title"], gift[@"number"], isWorn ? @"[НАДЕТ]" : @""];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Узор: %@ | Фон: %@", gift[@"pattern"], gift[@"backdrop"]];
            if (isWorn) {
                cell.textLabel.textColor = [UIColor colorWithRed:1.0 green:0.85 blue:0.3 alpha:1.0];
            }
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"➕ Добавить новый NFT Username";
            cell.detailTextLabel.text = @"Создать Fragment username без ограничений";
            cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
        } else {
            NSInteger idx = indexPath.row - 1;
            NSString *u = s.usernames[idx];
            BOOL isActive = (idx == s.activeUsernameIndex);
            cell.textLabel.text = [NSString stringWithFormat:@"@%@ %@", u, isActive ? @"✅ [АКТИВЕН]" : @""];
            cell.detailTextLabel.text = isActive ? @"Текущий отображаемый юзернейм" : @"Нажмите, чтобы активировать";
            if (isActive) cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:0.5 alpha:1.0];
        }
    } else if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"➕ Добавить новый +888 номер";
            cell.detailTextLabel.text = @"Создать анонимный номер без ограничений";
            cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
        } else {
            NSInteger idx = indexPath.row - 1;
            NSString *num = s.numbers[idx];
            BOOL isActive = (idx == s.activeNumberIndex);
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", num, isActive ? @"✅ [АКТИВЕН]" : @""];
            cell.detailTextLabel.text = isActive ? @"Текущий отображаемый номер" : @"Нажмите, чтобы активировать";
            if (isActive) cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:0.5 alpha:1.0];
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ChimeraStore *s = [ChimeraStore shared];

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⭐️ Накрутка Telegram Stars" message:@"Введите любое количество звёзд:" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.keyboardType = UIKeyboardTypeNumberPad;
                tf.text = [NSString stringWithFormat:@"%lld", s.starsBalance];
            }];
            [alert addAction:[UIAlertAction actionWithTitle:@"+100,000 ⭐️" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                s.starsBalance += 100000;
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"+1,000,000 ⭐️" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                s.starsBalance += 1000000;
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Сохранить своё число" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                s.starsBalance = [alert.textFields.firstObject.text longLongValue];
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else if (indexPath.row == 1) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"💎 Баланс GRAM" message:@"Введите баланс GRAM:" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.keyboardType = UIKeyboardTypeDecimalPad;
                tf.text = [NSString stringWithFormat:@"%.1f", s.gramBalance];
            }];
            [alert addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                s.gramBalance = [alert.textFields.firstObject.text doubleValue];
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔷 Баланс TON" message:@"Введите баланс TON:" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.keyboardType = UIKeyboardTypeDecimalPad;
                tf.text = [NSString stringWithFormat:@"%.1f", s.tonBalance];
            }];
            [alert addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                s.tonBalance = [alert.textFields.firstObject.text doubleValue];
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎁 Выдача NFT Подарка" message:@"Настройте модель, номер, узор и фон:" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Модель (Durov's Cap, King Pepe, Diamond)"; tf.text = @"Cyber Skull"; }];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Номер (#1, #777...)"; tf.text = @"777"; tf.keyboardType = UIKeyboardTypeNumberPad; }];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Узор (Звёзды, Короны, Кристаллы, Космос)"; tf.text = @"Золотые Звёзды (Gold Stars)"; }];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Фон (Неон, Золото, Изумруд, Сапфир)"; tf.text = @"Неон Киберпанк (#1F2338)"; }];

            [alert addAction:[UIAlertAction actionWithTitle:@"Выдать и Надеть" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                NSString *name = alert.textFields[0].text;
                int num = [alert.textFields[1].text intValue];
                NSString *pat = alert.textFields[2].text;
                NSString *bg = alert.textFields[3].text;

                NSMutableDictionary *newGift = [@{
                    @"title": name,
                    @"number": @(num),
                    @"model": @"custom",
                    @"backdrop": bg,
                    @"pattern": pat,
                    @"isWorn": @YES
                } mutableCopy];

                [s.gifts addObject:newGift];
                s.activeWornGiftIndex = s.gifts.count - 1;
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            NSInteger idx = indexPath.row - 1;
            s.activeWornGiftIndex = idx;
            [s save];
            [self setupHeaderCard];
            [self.tableView reloadData];
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🏷️ Новый NFT Username" message:@"Введите username (без @):" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"username"; tf.text = @"vip"; }];
            [alert addAction:[UIAlertAction actionWithTitle:@"Создать и Активировать" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                NSString *u = [alert.textFields.firstObject.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
                if (u.length > 0) {
                    [s.usernames addObject:u];
                    s.activeUsernameIndex = s.usernames.count - 1;
                    [s save];
                    [self setupHeaderCard];
                    [self.tableView reloadData];
                }
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            NSInteger idx = indexPath.row - 1;
            s.activeUsernameIndex = idx;
            [s save];
            [self setupHeaderCard];
            [self.tableView reloadData];
        }
    } else if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"📞 Новый +888 Номер" message:@"Введите анонимный номер:" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"+888 XXXX XXXX"; tf.text = @"+888 7777 9999"; }];
            [alert addAction:[UIAlertAction actionWithTitle:@"Создать и Активировать" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                NSString *num = alert.textFields.firstObject.text;
                if (num.length > 0) {
                    [s.numbers addObject:num];
                    s.activeNumberIndex = s.numbers.count - 1;
                    [s save];
                    [self setupHeaderCard];
                    [self.tableView reloadData];
                }
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            NSInteger idx = indexPath.row - 1;
            s.activeNumberIndex = idx;
            [s save];
            [self setupHeaderCard];
            [self.tableView reloadData];
        }
    }
}

@end

#pragma mark - Плавающая кнопка и действия

static UIViewController *getTopMostViewController(void) {
    UIWindow *keyWin = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) { keyWin = w; break; }
                    if (!keyWin && !w.hidden && w.bounds.size.width > 100) keyWin = w;
                }
            }
            if (keyWin && keyWin.isKeyWindow) break;
        }
    }
    if (!keyWin) {
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) { keyWin = w; break; }
            if (!keyWin && !w.hidden && w.bounds.size.width > 100) keyWin = w;
        }
    }
    if (!keyWin) {
        keyWin = [UIApplication sharedApplication].keyWindow;
    }
    UIViewController *top = keyWin.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    if ([top isKindOfClass:[UINavigationController class]]) {
        top = [(UINavigationController *)top visibleViewController] ?: top;
    } else if ([top isKindOfClass:[UITabBarController class]]) {
        top = [(UITabBarController *)top selectedViewController] ?: top;
    }
    return top;
}

static UIWindow *getAppMainWindow(void) {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) return w;
                    if (!window && !w.hidden && w.bounds.size.width > 100) window = w;
                }
            }
        }
    }
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) return w;
        if (!window && !w.hidden && w.bounds.size.width > 100) window = w;
    }
    if (!window) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    return window;
}

@interface UIButton (ChimeraFloatingActions)
- (void)chimeraOpenAction:(id)sender;
- (void)chimeraFloatingPanned:(UIPanGestureRecognizer *)gesture;
@end

@implementation UIButton (ChimeraFloatingActions)

- (void)chimeraOpenAction:(id)sender {
    UIViewController *topVC = getTopMostViewController();
    if (!topVC) return;
    if ([topVC isKindOfClass:[ChimeraNFTSettingsViewController class]] || 
        ([topVC isKindOfClass:[UINavigationController class]] && [((UINavigationController *)topVC).topViewController isKindOfClass:[ChimeraNFTSettingsViewController class]])) {
        return;
    }
    ChimeraNFTSettingsViewController *chimeraVC = [[ChimeraNFTSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:chimeraVC];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [topVC presentViewController:nav animated:YES completion:nil];
}

- (void)chimeraFloatingPanned:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    CGPoint translation = [gesture translationInView:btn.superview];
    CGFloat newX = btn.center.x + translation.x;
    CGFloat newY = btn.center.y + translation.y;
    CGRect b = btn.superview ? btn.superview.bounds : [UIScreen mainScreen].bounds;
    CGFloat hw = btn.bounds.size.width / 2.0;
    CGFloat hh = btn.bounds.size.height / 2.0;
    newX = MAX(hw + 6, MIN(b.size.width - hw - 6, newX));
    newY = MAX(hh + 44, MIN(b.size.height - hh - 24, newY));
    btn.center = CGPointMake(newX, newY);
    [gesture setTranslation:CGPointZero inView:btn.superview];
}

@end

#pragma mark - UI Внедрение кнопки

static void ensureFloatingChimeraButton() {
    UIWindow *window = getAppMainWindow();
    if (!window) return;

    if ([window viewWithTag:CHIMERA_FLOATING_TAG]) {
        UIView *existing = [window viewWithTag:CHIMERA_FLOATING_TAG];
        [window bringSubviewToFront:existing];
        return;
    }

    CGFloat screenW = window.bounds.size.width;
    UIButton *pill = [UIButton buttonWithType:UIButtonTypeCustom];
    pill.tag = CHIMERA_FLOATING_TAG;
    pill.frame = CGRectMake(screenW - 110, 115, 100, 36);
    pill.backgroundColor = [UIColor colorWithRed:0.06 green:0.10 blue:0.18 alpha:0.96];
    pill.layer.cornerRadius = 18;
    pill.layer.borderWidth = 1.6;
    pill.layer.borderColor = [UIColor colorWithRed:0.0 green:0.82 blue:1.0 alpha:0.9].CGColor;
    pill.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.82 blue:1.0 alpha:0.5].CGColor;
    pill.layer.shadowOffset = CGSizeMake(0, 3);
    pill.layer.shadowRadius = 8;
    pill.layer.shadowOpacity = 0.95;

    UILabel *title = [[UILabel alloc] initWithFrame:pill.bounds];
    title.text = @"👑 Chimera";
    title.font = [UIFont boldSystemFontOfSize:13];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.userInteractionEnabled = NO;
    [pill addSubview:title];

    [pill addTarget:pill action:@selector(chimeraOpenAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:pill action:@selector(chimeraOpenAction:)];
    tap.cancelsTouchesInView = NO;
    [pill addGestureRecognizer:tap];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:pill action:@selector(chimeraFloatingPanned:)];
    pan.cancelsTouchesInView = NO;
    [pill addGestureRecognizer:pan];

    // Жест 2 пальцами дважды тапнуть по окну (запасной вход в меню из любого места)
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:pill action:@selector(chimeraOpenAction:)];
    twoFingerTap.numberOfTouchesRequired = 2;
    twoFingerTap.numberOfTapsRequired = 2;
    twoFingerTap.cancelsTouchesInView = NO;
    [window addGestureRecognizer:twoFingerTap];

    [window addSubview:pill];
    [window bringSubviewToFront:pill];
}

static void ensureSettingsChimeraButton(UIViewController *self) {
    UIView *existingBtn = [self.view viewWithTag:CHIMERA_BTN_TAG];
    if (existingBtn) {
        [existingBtn removeFromSuperview];
    }

    ChimeraStore *s = [ChimeraStore shared];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = CHIMERA_BTN_TAG;
    btn.frame = CGRectMake(16, 72, self.view.bounds.size.width - 32, 58);
    btn.backgroundColor = [UIColor colorWithRed:0.10 green:0.13 blue:0.19 alpha:0.96];
    btn.layer.cornerRadius = 14;
    btn.layer.borderWidth = 1.3;
    btn.layer.borderColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:0.7].CGColor;
    btn.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:0.3].CGColor;
    btn.layer.shadowOffset = CGSizeMake(0, 4);
    btn.layer.shadowRadius = 8;
    btn.layer.shadowOpacity = 0.8;

    UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 14, 30, 30)];
    iconLabel.text = @"👑";
    iconLabel.font = [UIFont systemFontOfSize:22];
    [btn addSubview:iconLabel];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, 10, btn.bounds.size.width - 80, 20)];
    titleLabel.text = @"Chimera NFT";
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor whiteColor];
    [btn addSubview:titleLabel];

    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, 30, btn.bounds.size.width - 80, 18)];
    subLabel.text = [NSString stringWithFormat:@"⭐️ %lld Stars  •  💎 %.1f GRAM  •  @%@", s.starsBalance, s.gramBalance, [s currentUsername]];
    subLabel.font = [UIFont systemFontOfSize:12];
    subLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
    [btn addSubview:subLabel];

    UILabel *arrow = [[UILabel alloc] initWithFrame:CGRectMake(btn.bounds.size.width - 26, 19, 20, 20)];
    arrow.text = @"›";
    arrow.font = [UIFont systemFontOfSize:24 weight:UIFontWeightRegular];
    arrow.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    [btn addSubview:arrow];

    [btn addTarget:btn action:@selector(chimeraOpenAction:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:btn];
    [self.view bringSubviewToFront:btn];
}

#pragma mark - Хук UIViewController

static void (*orig_viewDidAppear)(UIViewController *, SEL, BOOL);
static void hook_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);

    dispatch_async(dispatch_get_main_queue(), ^{
        ensureFloatingChimeraButton();
    });

    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"PeerInfo"] || 
        [className containsString:@"Settings"] || 
        [className containsString:@"Profile"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ensureSettingsChimeraButton(self);
        });
    }
}

// 1. Хук isPremium
static BOOL (*orig_isPremium)(id, SEL);
static BOOL hook_isPremium(id self, SEL _cmd) {
    return YES;
}

// 2. Хук starsBalance
static long long (*orig_starsBalance)(id, SEL);
static long long hook_starsBalance(id self, SEL _cmd) {
    return [ChimeraStore shared].starsBalance;
}

__attribute__((constructor))
static void initializeExteraChimera() {
    NSLog(@"[exteraGram] Твик ExteraChimeraTweak v4 (Плавающая кнопка + Настройки + Stars + GRAM + NFT) загружен!");

    // 1. Хук isPremium
    Class userClass = objc_getClass("_TtC12TelegramCore12TelegramUser") 
                   ?: objc_getClass("TelegramCore.TelegramUser") 
                   ?: objc_getClass("TelegramUser");
    if (userClass) {
        Method m = class_getInstanceMethod(userClass, sel_registerName("isPremium"));
        if (m) {
            orig_isPremium = (BOOL (*)(id, SEL))method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_isPremium);
            NSLog(@"[exteraGram] Хук isPremium активирован!");
        }
    }

    // 2. Хук starsBalance
    Class starsClass = objc_getClass("_TtC12TelegramCore12StarsContext") 
                    ?: objc_getClass("TelegramCore.StarsContext") 
                    ?: objc_getClass("StarsContext");
    if (starsClass) {
        Method m = class_getInstanceMethod(starsClass, sel_registerName("starsBalance"));
        if (m) {
            orig_starsBalance = (long long (*)(id, SEL))method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_starsBalance);
            NSLog(@"[exteraGram] Хук starsBalance активирован!");
        }
    }

    // 3. Хук UIViewController: ГАРАНТИРОВАНО работает на ВСЕХ экранах Telegram
    Class vcClass = [UIViewController class];
    if (vcClass) {
        Method m = class_getInstanceMethod(vcClass, @selector(viewDidAppear:));
        if (m) {
            orig_viewDidAppear = (void (*)(UIViewController *, SEL, BOOL))method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_viewDidAppear);
            NSLog(@"[exteraGram] Хук UIViewController viewDidAppear успешно установлен!");
        }
    }
}
