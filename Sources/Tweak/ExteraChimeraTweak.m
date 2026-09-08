//
//  ExteraChimeraTweak.m
//  Твик для интеграции Chimera NFT & Teledark в Telegram 12.9.2:
//  1. Нативная кнопка в Navigation Bar как у Teledark (никаких плавающих кнопок на экране!).
//  2. Магазин Fake NFT: покупка подарков за Stars / GRAM и конструктор кастомных NFT.
//  3. Раздел «Мои подарки»: хранение всех выданных NFT и функция «Надеть в профиль (Wear Gift)».
//  4. Накрутка баланса Telegram Stars (Звёзды), токенов GRAM и TON.
//  5. Локальный Telegram Premium (значок ⭐ Premium, разблокировка функций).
//  6. Бесконечные Fragment @Username и анонимные +888 номера.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define CHIMERA_STORAGE_KEY @"chimeranft_master_storage_v4"
#define TELEDARK_NAV_TAG 77701
#define CHIMERA_FLOATING_TAG 77703

#pragma mark - Хранилище данных ChimeraStore

@interface ChimeraStore : NSObject
+ (instancetype)shared;

@property (nonatomic, assign) long long starsBalance;
@property (nonatomic, assign) double gramBalance;
@property (nonatomic, assign) double tonBalance;
@property (nonatomic, assign) BOOL spendStarsOnBuy;
@property (nonatomic, assign) BOOL localPremiumEnabled;
@property (nonatomic, assign) BOOL hideRegularGifts;

@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *gifts;
@property (nonatomic, assign) NSInteger activeWornGiftIndex;

@property (nonatomic, strong) NSMutableArray<NSString *> *usernames;
@property (nonatomic, assign) NSInteger activeUsernameIndex;

@property (nonatomic, strong) NSMutableArray<NSString *> *numbers;
@property (nonatomic, assign) NSInteger activeNumberIndex;

@property (nonatomic, assign) NSInteger ratingScore;
@property (nonatomic, assign) NSInteger ratingLevel;

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
        self.spendStarsOnBuy = [data[@"spend_stars"] boolValue];
        self.localPremiumEnabled = data[@"premium"] ? [data[@"premium"] boolValue] : YES;
        self.hideRegularGifts = data[@"hide_regular"] ? [data[@"hide_regular"] boolValue] : YES;

        self.usernames = [NSMutableArray arrayWithArray:data[@"usernames"] ?: @[@"chimera", @"durov", @"ton_holder"]];
        self.activeUsernameIndex = [data[@"active_user_idx"] integerValue];

        self.numbers = [NSMutableArray arrayWithArray:data[@"numbers"] ?: @[@"+888 0123 4567", @"+888 7777 7777"]];
        self.activeNumberIndex = [data[@"active_num_idx"] integerValue];

        self.ratingScore = [data[@"rating_score"] integerValue] ?: 9999;
        self.ratingLevel = [data[@"rating_level"] integerValue] ?: 5;

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
        self.spendStarsOnBuy = NO;
        self.localPremiumEnabled = YES;
        self.hideRegularGifts = YES;

        self.usernames = [NSMutableArray arrayWithArray:@[@"chimera", @"durov", @"nft_king", @"ton_whale"]];
        self.activeUsernameIndex = 0;

        self.numbers = [NSMutableArray arrayWithArray:@[@"+888 0123 4567", @"+888 7777 7777", @"+888 8888 8888"]];
        self.activeNumberIndex = 0;

        self.ratingScore = 9999;
        self.ratingLevel = 5;
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
            @"priceStars": @10000,
            @"priceGram": @25,
            @"isWorn": @YES
        } mutableCopy],
        [@{
            @"title": @"Cyber Skull",
            @"number": @777,
            @"model": @"skull",
            @"backdrop": @"Киберпанк Неон (#220935)",
            @"pattern": @"Черепа и Молнии",
            @"rarity": @"Legendary",
            @"priceStars": @5000,
            @"priceGram": @15,
            @"isWorn": @NO
        } mutableCopy],
        [@{
            @"title": @"King Pepe",
            @"number": @69,
            @"model": @"pepe",
            @"backdrop": @"Изумрудный Блеск (#152F24)",
            @"pattern": @"Короны (Crowns)",
            @"rarity": @"Mythic",
            @"priceStars": @7500,
            @"priceGram": @20,
            @"isWorn": @NO
        } mutableCopy]
    ]];
}

- (NSString *)currentUsername {
    if (self.activeUsernameIndex >= 0 && self.activeUsernameIndex < self.usernames.count) {
        return self.usernames[self.activeUsernameIndex];
    }
    return @"chimera";
}

- (NSString *)currentNumber {
    if (self.activeNumberIndex >= 0 && self.activeNumberIndex < self.numbers.count) {
        return self.numbers[self.activeNumberIndex];
    }
    return @"+888 0123 4567";
}

- (NSDictionary *)currentWornGift {
    if (self.activeWornGiftIndex >= 0 && self.activeWornGiftIndex < self.gifts.count) {
        return self.gifts[self.activeWornGiftIndex];
    }
    return nil;
}

- (void)save {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"stars"] = @(self.starsBalance);
    dict[@"gram"] = @(self.gramBalance);
    dict[@"ton"] = @(self.tonBalance);
    dict[@"spend_stars"] = @(self.spendStarsOnBuy);
    dict[@"premium"] = @(self.localPremiumEnabled);
    dict[@"hide_regular"] = @(self.hideRegularGifts);

    dict[@"usernames"] = self.usernames;
    dict[@"active_user_idx"] = @(self.activeUsernameIndex);

    dict[@"numbers"] = self.numbers;
    dict[@"active_num_idx"] = @(self.activeNumberIndex);

    dict[@"rating_score"] = @(self.ratingScore);
    dict[@"rating_level"] = @(self.ratingLevel);

    dict[@"active_gift_idx"] = @(self.activeWornGiftIndex);
    dict[@"gifts"] = self.gifts;

    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:CHIMERA_STORAGE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

#pragma mark - Экран управления Chimera NFT & Teledark (ChimeraNFTSettingsViewController)

@interface ChimeraNFTSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSArray<NSDictionary *> *marketCatalog;
@end

@implementation ChimeraNFTSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"👑 Chimera NFT & Teledark";
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.14 alpha:1.0];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone target:self action:@selector(closeTapped)];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0 green:0.80 blue:1.0 alpha:1.0];

    [self setupMarketCatalog];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.14 alpha:1.0];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [self setupHeaderCard];
}

- (void)setupMarketCatalog {
    self.marketCatalog = @[
        @{ @"title": @"Durov's Cap", @"number": @1, @"model": @"cap", @"backdrop": @"Неон / Космос (#1F2338)", @"pattern": @"Золотые Звёзды (Gold Stars)", @"stars": @10000, @"gram": @25, @"emoji": @"🧢" },
        @{ @"title": @"Cyber Skull", @"number": @777, @"model": @"skull", @"backdrop": @"Киберпанк Неон (#220935)", @"pattern": @"Черепа и Молнии", @"stars": @5000, @"gram": @15, @"emoji": @"💀" },
        @{ @"title": @"King Pepe", @"number": @69, @"model": @"pepe", @"backdrop": @"Изумрудный Блеск (#152F24)", @"pattern": @"Короны (Crowns)", @"stars": @7500, @"gram": @20, @"emoji": @"🐸" },
        @{ @"title": @"Astronaut Diamond", @"number": @100, @"model": @"gem", @"backdrop": @"Тёмный Сапфир (#1B2A4A)", @"pattern": @"Кристаллы (Cyan Crystals)", @"stars": @15000, @"gram": @40, @"emoji": @"💎" },
        @{ @"title": @"Plush Pepe", @"number": @420, @"model": @"plush", @"backdrop": @"Мягкий Неон (#2E1F3B)", @"pattern": @"Сердечки (Hearts)", @"stars": @3000, @"gram": @10, @"emoji": @"🧸" },
        @{ @"title": @"Golden Star Trophy", @"number": @7, @"model": @"trophy", @"backdrop": @"Имперское Золото (#382E12)", @"pattern": @"Звёзды Славы", @"stars": @20000, @"gram": @50, @"emoji": @"🏆" },
        @{ @"title": @"B-Day Candle 2026", @"number": @888, @"model": @"candle", @"backdrop": @"Тёплый Закат (#3B1D1D)", @"pattern": @"Огни Праздника", @"stars": @2500, @"gram": @8, @"emoji": @"🕯️" },
        @{ @"title": @"Ton Whale", @"number": @999, @"model": @"whale", @"backdrop": @"Глубокий Океан (#0B2338)", @"pattern": @"Волны TON", @"stars": @25000, @"gram": @60, @"emoji": @"🐋" },
        @{ @"title": @"➕ Создать свой кастомный NFT", @"number": @0, @"model": @"custom", @"backdrop": @"Кастомный выбор", @"pattern": @"Любой узор", @"stars": @0, @"gram": @0, @"emoji": @"✨" }
    ];
}

- (void)segmentChanged:(UISegmentedControl *)sc {
    [self.tableView reloadData];
}

- (void)setupHeaderCard {
    ChimeraStore *s = [ChimeraStore shared];
    CGFloat w = self.view.bounds.size.width > 100 ? self.view.bounds.size.width : [UIScreen mainScreen].bounds.size.width;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 206)];

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16, 8, w - 32, 140)];
    card.backgroundColor = [UIColor colorWithRed:0.11 green:0.14 blue:0.22 alpha:0.96];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1.3;
    card.layer.borderColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:0.7].CGColor;
    card.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:card];

    UILabel *badge = [[UILabel alloc] initWithFrame:CGRectMake(14, 10, card.bounds.size.width - 28, 18)];
    badge.text = s.localPremiumEnabled ? @"👑 CHIMERA NFT  •  ⭐ LOCAL PREMIUM [АКТИВЕН]" : @"👑 CHIMERA NFT  •  ⭐ PREMIUM [ВЫКЛ]";
    badge.font = [UIFont boldSystemFontOfSize:11];
    badge.textColor = s.localPremiumEnabled ? [UIColor colorWithRed:0.2 green:0.85 blue:1.0 alpha:1.0] : [UIColor colorWithWhite:0.6 alpha:1.0];
    badge.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [card addSubview:badge];

    UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 28, card.bounds.size.width - 28, 28)];
    userLabel.text = [NSString stringWithFormat:@"@%@ %@", [s currentUsername], s.localPremiumEnabled ? @"⭐" : @""];
    userLabel.font = [UIFont boldSystemFontOfSize:22];
    userLabel.textColor = [UIColor whiteColor];
    userLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [card addSubview:userLabel];

    UILabel *numLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 58, card.bounds.size.width - 28, 18)];
    numLabel.text = [NSString stringWithFormat:@"📞 %@   •   🏆 Уровень %ld (%ld pts)", [s currentNumber], (long)s.ratingLevel, (long)s.ratingScore];
    numLabel.font = [UIFont systemFontOfSize:12];
    numLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    numLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [card addSubview:numLabel];

    NSDictionary *worn = [s currentWornGift];
    UILabel *wornLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 80, card.bounds.size.width - 28, 18)];
    if (worn) {
        wornLabel.text = [NSString stringWithFormat:@"🎁 Надет в профиле: %@ #%@ [%@]", worn[@"title"], worn[@"number"], worn[@"pattern"] ?: @"NFT"];
        wornLabel.textColor = [UIColor colorWithRed:1.0 green:0.82 blue:0.2 alpha:1.0];
    } else {
        wornLabel.text = @"🎁 Надет в профиле: Нет надетого NFT подарка";
        wornLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    }
    wornLabel.font = [UIFont boldSystemFontOfSize:11];
    wornLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [card addSubview:wornLabel];

    UILabel *balLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 104, card.bounds.size.width - 28, 26)];
    balLabel.text = [NSString stringWithFormat:@"⭐️ %lld Stars   💎 %.1f GRAM   🔷 %.1f TON", s.starsBalance, s.gramBalance, s.tonBalance];
    balLabel.font = [UIFont boldSystemFontOfSize:13];
    balLabel.textColor = [UIColor colorWithRed:0.15 green:0.92 blue:0.55 alpha:1.0];
    balLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [card addSubview:balLabel];

    // Segmented control right under the card
    if (!self.segmentedControl) {
        NSArray *items = @[@"🛍️ Маркет", @"🎁 Подарки", @"⭐️ Баланс", @"🏷️ Профиль"];
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
        self.segmentedControl.selectedSegmentIndex = 0;
        self.segmentedControl.backgroundColor = [UIColor colorWithRed:0.12 green:0.15 blue:0.22 alpha:1.0];
        self.segmentedControl.selectedSegmentTintColor = [UIColor colorWithRed:0.0 green:0.65 blue:0.95 alpha:1.0];
        [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:12]} forState:UIControlStateSelected];
        [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.75 alpha:1.0], NSFontAttributeName: [UIFont systemFontOfSize:12]} forState:UIControlStateNormal];
        [self.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    }
    self.segmentedControl.frame = CGRectMake(16, 158, w - 32, 36);
    self.segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:self.segmentedControl];

    self.tableView.tableHeaderView = header;
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView DataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger seg = self.segmentedControl.selectedSegmentIndex;
    if (seg == 0) return 1; // Маркет
    if (seg == 1) return 2; // Мои подарки + Настройки отображения
    if (seg == 2) return 3; // Баланс Stars, GRAM, Опции списания
    if (seg == 3) return 4; // Premium, Username, Номер, Рейтинг
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger seg = self.segmentedControl.selectedSegmentIndex;
    if (seg == 0) {
        return @"🛍️ ВЫДАЧА И ПОКУПКА FAKE NFT ПОДАРКОВ";
    } else if (seg == 1) {
        if (section == 0) return @"🎁 МОИ ПОЛУЧЕННЫЕ NFT ПОДАРКИ";
        return @"⚙️ ОТОБРАЖЕНИЕ В ПРОФИЛЕ";
    } else if (seg == 2) {
        if (section == 0) return @"⭐️ БАЛАНС TELEGRAM STARS (НАКРУТКА)";
        if (section == 1) return @"💎 БАЛАНС ТОКЕНОВ GRAM И TON";
        return @"🛒 ОПЦИИ СПИСАНИЯ ПРИ ПОКУПКЕ";
    } else if (seg == 3) {
        if (section == 0) return @"⭐ ЛОКАЛЬНЫЙ TELEGRAM PREMIUM";
        if (section == 1) return @"🏷️ COLLECTIBLE @USERNAME (FRAGMENT)";
        if (section == 2) return @"📞 АНОНИМНЫЕ +888 НОМЕРА";
        return @"🏆 РЕЙТИНГ ПРОФИЛЯ";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger seg = self.segmentedControl.selectedSegmentIndex;
    ChimeraStore *s = [ChimeraStore shared];

    if (seg == 0) {
        return self.marketCatalog.count;
    } else if (seg == 1) {
        if (section == 0) return s.gifts.count > 0 ? s.gifts.count : 1;
        return 1; // Скрыть обычные подарки
    } else if (seg == 2) {
        if (section == 0) return 4; // +10k, +100k, +1M, Своё число
        if (section == 1) return 3; // +500 GRAM, +2500 GRAM, +100 TON
        return 1; // Свитч тратить звёзды
    } else if (seg == 3) {
        if (section == 0) return 1; // Свитч Premium
        if (section == 1) return 1 + s.usernames.count; // Добавить + список
        if (section == 2) return 1 + s.numbers.count; // Добавить + список
        return 2; // Уровень и очки
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChimeraStore *s = [ChimeraStore shared];
    NSInteger seg = self.segmentedControl.selectedSegmentIndex;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChimeraCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ChimeraCell"];
    }
    cell.backgroundColor = [UIColor colorWithRed:0.11 green:0.14 blue:0.22 alpha:0.96];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;

    if (seg == 0) {
        // МАРКЕТ FAKE NFT
        NSDictionary *item = self.marketCatalog[indexPath.row];
        NSString *emoji = item[@"emoji"] ?: @"🎁";
        NSString *title = item[@"title"];
        NSNumber *num = item[@"number"];
        NSNumber *stars = item[@"stars"];
        NSNumber *gram = item[@"gram"];

        if ([num intValue] == 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", emoji, title];
            cell.detailTextLabel.text = @"Любая модель, номер, узор и фон на ваш выбор (Бесплатно)";
            cell.textLabel.textColor = [UIColor colorWithRed:0.15 green:0.92 blue:0.55 alpha:1.0];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ #%@", emoji, title, num];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · ⭐️ %@ Stars / 💎 %@ GRAM", item[@"backdrop"], stars, gram];
            cell.textLabel.textColor = [UIColor whiteColor];
        }
    } else if (seg == 1) {
        // МОИ ПОДАРКИ
        if (indexPath.section == 0) {
            if (s.gifts.count == 0) {
                cell.textLabel.text = @"Пока нет NFT подарков";
                cell.detailTextLabel.text = @"Перейдите во вкладку «Маркет», чтобы выдать себе подарок";
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                NSDictionary *g = s.gifts[indexPath.row];
                BOOL isWorn = (indexPath.row == s.activeWornGiftIndex);
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ #%@ %@", isWorn ? @"👑" : @"🎁", g[@"title"], g[@"number"], isWorn ? @"[НАДЕТ В ПРОФИЛЕ]" : @""];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Узор: %@ · Фон: %@", g[@"pattern"], g[@"backdrop"]];
                if (isWorn) {
                    cell.textLabel.textColor = [UIColor colorWithRed:1.0 green:0.82 blue:0.2 alpha:1.0];
                } else {
                    cell.textLabel.textColor = [UIColor whiteColor];
                }
            }
        } else {
            cell.textLabel.text = @"Скрыть обычные подарки Telegram";
            cell.detailTextLabel.text = @"В профиле будут видны только ваши NFT подарки";
            UISwitch *sw = [[UISwitch alloc] init];
            [sw setOn:s.hideRegularGifts animated:NO];
            [sw addTarget:self action:@selector(hideRegularToggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        }
    } else if (seg == 2) {
        // БАЛАНС
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"⭐️ +10,000 Stars (Звёзд)";
                cell.detailTextLabel.text = @"Мгновенно начислить на баланс";
            } else if (indexPath.row == 1) {
                cell.textLabel.text = @"⭐️ +100,000 Stars (Звёзд)";
                cell.detailTextLabel.text = @"Мгновенно начислить на баланс";
            } else if (indexPath.row == 2) {
                cell.textLabel.text = @"⭐️ +1,000,000 Stars (Звёзд)";
                cell.detailTextLabel.text = @"Мгновенно начислить на баланс";
            } else {
                cell.textLabel.text = @"✏️ Ввести своё количество Stars";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Текущий: %lld Stars", s.starsBalance];
                cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
            }
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"💎 +500 GRAM";
                cell.detailTextLabel.text = @"Мгновенно начислить на баланс";
            } else if (indexPath.row == 1) {
                cell.textLabel.text = @"💎 +2,500 GRAM";
                cell.detailTextLabel.text = @"Мгновенно начислить на баланс";
            } else {
                cell.textLabel.text = @"🔷 +100 TON";
                cell.detailTextLabel.text = @"Мгновенно начислить на баланс";
            }
        } else {
            cell.textLabel.text = @"Тратить баланс при покупках в маркете";
            cell.detailTextLabel.text = s.spendStarsOnBuy ? @"Покупки списывают баланс Stars" : @"Покупки бесплатны, баланс остаётся неизменным";
            UISwitch *sw = [[UISwitch alloc] init];
            [sw setOn:s.spendStarsOnBuy animated:NO];
            [sw addTarget:self action:@selector(spendStarsToggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        }
    } else if (seg == 3) {
        // ПРОФИЛЬ & PREMIUM
        if (indexPath.section == 0) {
            cell.textLabel.text = @"Локальный Telegram Premium";
            cell.detailTextLabel.text = s.localPremiumEnabled ? @"Включён · значок ⭐ Premium и функции активны" : @"Выключен";
            UISwitch *sw = [[UISwitch alloc] init];
            [sw setOn:s.localPremiumEnabled animated:NO];
            [sw addTarget:self action:@selector(premiumToggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"➕ Добавить новый Fragment @username";
                cell.detailTextLabel.text = @"Любой никнейм без ограничений";
                cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
            } else {
                NSInteger idx = indexPath.row - 1;
                NSString *u = s.usernames[idx];
                BOOL isAct = (idx == s.activeUsernameIndex);
                cell.textLabel.text = [NSString stringWithFormat:@"@%@ %@", u, isAct ? @"✅ [АКТИВЕН]" : @""];
                cell.detailTextLabel.text = isAct ? @"Отображается в профиле и чатах" : @"Нажмите, чтобы сделать активным";
                if (isAct) cell.textLabel.textColor = [UIColor colorWithRed:0.15 green:0.92 blue:0.55 alpha:1.0];
            }
        } else if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"➕ Добавить новый +888 номер";
                cell.detailTextLabel.text = @"Любой анонимный номер Fragment";
                cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:1.0];
            } else {
                NSInteger idx = indexPath.row - 1;
                NSString *num = s.numbers[idx];
                BOOL isAct = (idx == s.activeNumberIndex);
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", num, isAct ? @"✅ [АКТИВЕН]" : @""];
                cell.detailTextLabel.text = isAct ? @"Отображается в профиле" : @"Нажмите, чтобы сделать активным";
                if (isAct) cell.textLabel.textColor = [UIColor colorWithRed:0.15 green:0.92 blue:0.55 alpha:1.0];
            }
        } else {
            if (indexPath.row == 0) {
                cell.textLabel.text = [NSString stringWithFormat:@"Уровень рейтинга: %ld", (long)s.ratingLevel];
                cell.detailTextLabel.text = @"Нажмите, чтобы изменить уровень (1–10)";
            } else {
                cell.textLabel.text = [NSString stringWithFormat:@"Очки рейтинга: %ld pts", (long)s.ratingScore];
                cell.detailTextLabel.text = @"Нажмите, чтобы изменить количество очков";
            }
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ChimeraStore *s = [ChimeraStore shared];
    NSInteger seg = self.segmentedControl.selectedSegmentIndex;

    if (seg == 0) {
        // Клик по товару в маркете
        NSDictionary *item = self.marketCatalog[indexPath.row];
        NSNumber *num = item[@"number"];

        if ([num intValue] == 0) {
            // Конструктор кастомного NFT
            [self openCustomNFTConstructor];
        } else {
            [self buyMarketItem:item];
        }
    } else if (seg == 1) {
        // Клик по подарку в списке
        if (indexPath.section == 0 && s.gifts.count > 0) {
            [self handleGiftAction:indexPath.row];
        }
    } else if (seg == 2) {
        // Накрутка баланса
        if (indexPath.section == 0) {
            if (indexPath.row == 0) { s.starsBalance += 10000; }
            else if (indexPath.row == 1) { s.starsBalance += 100000; }
            else if (indexPath.row == 2) { s.starsBalance += 1000000; }
            else {
                [self openCustomStarsInput];
                return;
            }
            [s save];
            [self setupHeaderCard];
            [self.tableView reloadData];
            [self showToast:@"⭐️ Баланс Stars успешно пополнен!"];
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) { s.gramBalance += 500.0; }
            else if (indexPath.row == 1) { s.gramBalance += 2500.0; }
            else { s.tonBalance += 100.0; }
            [s save];
            [self setupHeaderCard];
            [self.tableView reloadData];
            [self showToast:@"💎 Баланс токенов успешно пополнен!"];
        }
    } else if (seg == 3) {
        if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                [self openAddUsernameDialog];
            } else {
                s.activeUsernameIndex = indexPath.row - 1;
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
                [self showToast:[NSString stringWithFormat:@"Активен username @%@", [s currentUsername]]];
            }
        } else if (indexPath.section == 2) {
            if (indexPath.row == 0) {
                [self openAddNumberDialog];
            } else {
                s.activeNumberIndex = indexPath.row - 1;
                [s save];
                [self setupHeaderCard];
                [self.tableView reloadData];
                [self showToast:[NSString stringWithFormat:@"Активен номер %@", [s currentNumber]]];
            }
        } else if (indexPath.section == 3) {
            [self openRatingDialog:indexPath.row == 0];
        }
    }
}

#pragma mark - Действия маркета и подарков

- (void)buyMarketItem:(NSDictionary *)item {
    ChimeraStore *s = [ChimeraStore shared];
    long long priceStars = [item[@"stars"] longLongValue];
    double priceGram = [item[@"gram"] doubleValue];

    NSString *msg = [NSString stringWithFormat:@"Стоимость: %lld ⭐️ или %.1f 💎 GRAM\nМодель: %@ #%@\nФон: %@", priceStars, priceGram, item[@"title"], item[@"number"], item[@"backdrop"]];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Купить %@", item[@"title"]] message:msg preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Купить за %lld ⭐️", priceStars] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        if (s.spendStarsOnBuy && s.starsBalance < priceStars) {
            [self showTopUpSuggestion];
            return;
        }
        if (s.spendStarsOnBuy) {
            s.starsBalance -= priceStars;
        }
        [self completeGiftPurchase:item];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Купить за %.1f 💎 GRAM", priceGram] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        if (s.spendStarsOnBuy && s.gramBalance < priceGram) {
            s.gramBalance += 500;
        }
        if (s.spendStarsOnBuy) {
            s.gramBalance -= priceGram;
        }
        [self completeGiftPurchase:item];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Получить бесплатно" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self completeGiftPurchase:item];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)completeGiftPurchase:(NSDictionary *)item {
    ChimeraStore *s = [ChimeraStore shared];
    NSMutableDictionary *newGift = [@{
        @"title": item[@"title"],
        @"number": item[@"number"],
        @"model": item[@"model"] ?: @"custom",
        @"backdrop": item[@"backdrop"] ?: @"Неон",
        @"pattern": item[@"pattern"] ?: @"Звёзды",
        @"isWorn": @YES
    } mutableCopy];

    [s.gifts addObject:newGift];
    s.activeWornGiftIndex = s.gifts.count - 1;
    [s save];

    [self setupHeaderCard];
    [self.tableView reloadData];

    UIAlertController *ok = [UIAlertController alertControllerWithTitle:@"🎉 Успешно!" message:[NSString stringWithFormat:@"NFT Подарок «%@ #%@» успешно куплен и надет в профиле!", item[@"title"], item[@"number"]] preferredStyle:UIAlertControllerStyleAlert];
    [ok addAction:[UIAlertAction actionWithTitle:@"Отлично" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:ok animated:YES completion:nil];
}

- (void)openCustomNFTConstructor {
    ChimeraStore *s = [ChimeraStore shared];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✨ Конструктор Fake NFT" message:@"Создайте абсолютно любой уникальный подарок:" preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Название модели"; tf.text = @"Cyber Skull"; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Уникальный номер (#1, #777)"; tf.text = @"777"; tf.keyboardType = UIKeyboardTypeNumberPad; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Узор (Звёзды, Короны, Кристаллы)"; tf.text = @"Золотые Звёзды (Gold Stars)"; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Фон карточки (Неон, Космос, Золото)"; tf.text = @"Неон Киберпанк (#1F2338)"; }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Создать и Надеть" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *title = alert.textFields[0].text;
        int num = [alert.textFields[1].text intValue];
        NSString *pat = alert.textFields[2].text;
        NSString *bg = alert.textFields[3].text;

        NSMutableDictionary *newGift = [@{
            @"title": title.length > 0 ? title : @"Custom NFT",
            @"number": @(num > 0 ? num : 1),
            @"model": @"custom",
            @"backdrop": bg.length > 0 ? bg : @"Неон (#1F2338)",
            @"pattern": pat.length > 0 ? pat : @"Звёзды",
            @"isWorn": @YES
        } mutableCopy];

        [s.gifts addObject:newGift];
        s.activeWornGiftIndex = s.gifts.count - 1;
        [s save];

        [self setupHeaderCard];
        [self.tableView reloadData];
        [self showToast:@"🎉 Кастомный NFT подарок создан и надет!"];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleGiftAction:(NSInteger)index {
    ChimeraStore *s = [ChimeraStore shared];
    NSDictionary *g = s.gifts[index];
    BOOL isWorn = (index == s.activeWornGiftIndex);

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ #%@", g[@"title"], g[@"number"]] message:[NSString stringWithFormat:@"Узор: %@\nФон: %@", g[@"pattern"], g[@"backdrop"]] preferredStyle:UIAlertControllerStyleActionSheet];

    if (!isWorn) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"👑 Надеть в профиль (Wear Gift)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            s.activeWornGiftIndex = index;
            [s save];
            [self setupHeaderCard];
            [self.tableView reloadData];
            [self showToast:@"Подарок надет в профиле!"];
        }]];
    } else {
        [sheet addAction:[UIAlertAction actionWithTitle:@"❌ Снять с профиля" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            s.activeWornGiftIndex = -1;
            [s save];
            [self setupHeaderCard];
            [self.tableView reloadData];
            [self showToast:@"Подарок снят"];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"🗑️ Удалить этот подарок" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        if (s.activeWornGiftIndex == index) s.activeWornGiftIndex = -1;
        else if (s.activeWornGiftIndex > index) s.activeWornGiftIndex--;
        [s.gifts removeObjectAtIndex:index];
        [s save];
        [self setupHeaderCard];
        [self.tableView reloadData];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showTopUpSuggestion {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"⭐️ Недостаточно Stars" message:@"Накрутить +100,000 звёзд прямо сейчас?" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Да, накрутить +100,000 ⭐️" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [ChimeraStore shared].starsBalance += 100000;
        [[ChimeraStore shared] save];
        [self setupHeaderCard];
        [self.tableView reloadData];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)openCustomStarsInput {
    ChimeraStore *s = [ChimeraStore shared];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⭐️ Ввести баланс Stars" message:@"Укажите любое количество звёзд:" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.text = [NSString stringWithFormat:@"%lld", s.starsBalance];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        s.starsBalance = [alert.textFields[0].text longLongValue];
        [s save];
        [self setupHeaderCard];
        [self.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openAddUsernameDialog {
    ChimeraStore *s = [ChimeraStore shared];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🏷️ Новый Fragment Username" message:@"Введите юзернейм (без @):" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"username"; tf.text = @"vip"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Добавить и Активировать" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *u = [alert.textFields[0].text stringByReplacingOccurrencesOfString:@"@" withString:@""];
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
}

- (void)openAddNumberDialog {
    ChimeraStore *s = [ChimeraStore shared];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"📞 Новый +888 Номер" message:@"Введите анонимный номер Fragment:" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"+888 XXXX XXXX"; tf.text = @"+888 7777 9999"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Добавить и Активировать" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *num = alert.textFields[0].text;
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
}

- (void)openRatingDialog:(BOOL)isLevel {
    ChimeraStore *s = [ChimeraStore shared];
    NSString *title = isLevel ? @"🏆 Уровень рейтинга" : @"🏆 Очки рейтинга";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:@"Введите значение:" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.text = [NSString stringWithFormat:@"%ld", (long)(isLevel ? s.ratingLevel : s.ratingScore)];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSInteger val = [alert.textFields[0].text integerValue];
        if (isLevel) s.ratingLevel = MAX(1, MIN(10, val));
        else s.ratingScore = MAX(0, val);
        [s save];
        [self setupHeaderCard];
        [self.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)hideRegularToggled:(UISwitch *)sw {
    [ChimeraStore shared].hideRegularGifts = sw.isOn;
    [[ChimeraStore shared] save];
}

- (void)spendStarsToggled:(UISwitch *)sw {
    [ChimeraStore shared].spendStarsOnBuy = sw.isOn;
    [[ChimeraStore shared] save];
}

- (void)premiumToggled:(UISwitch *)sw {
    [ChimeraStore shared].localPremiumEnabled = sw.isOn;
    [[ChimeraStore shared] save];
    [self setupHeaderCard];
    [self.tableView reloadData];
    [self showToast:sw.isOn ? @"⭐ Локальный Premium активирован!" : @"⭐ Premium отключен"];
}

- (void)showToast:(NSString *)text {
    UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(24, self.view.bounds.size.height - 100, self.view.bounds.size.width - 48, 40)];
    toast.backgroundColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:0.95];
    toast.textColor = [UIColor whiteColor];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont boldSystemFontOfSize:13];
    toast.layer.cornerRadius = 20;
    toast.layer.masksToBounds = YES;
    toast.text = text;
    [self.view addSubview:toast];

    [UIView animateWithDuration:0.4 delay:1.6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toast.alpha = 0.0;
    } completion:^(BOOL finished) {
        [toast removeFromSuperview];
    }];
}

@end

#pragma mark - Внедрение кнопки Teledark & Настройки

@interface UIViewController (TeledarkMenuAction)
- (void)teledarkOpenMenuAction:(id)sender;
@end

@implementation UIViewController (TeledarkMenuAction)

- (void)teledarkOpenMenuAction:(id)sender {
    ChimeraNFTSettingsViewController *vc = [[ChimeraNFTSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

@end

static void ensureTeledarkNavButton(UIViewController *vc) {
    if (!vc.navigationItem) return;

    // Проверяем, нет ли уже кнопки Teledark
    for (UIBarButtonItem *item in vc.navigationItem.rightBarButtonItems) {
        if (item.tag == TELEDARK_NAV_TAG) return;
    }
    if (vc.navigationItem.rightBarButtonItem && vc.navigationItem.rightBarButtonItem.tag == TELEDARK_NAV_TAG) return;

    // Создаем нативную кнопку в стиле Teledark
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = TELEDARK_NAV_TAG;
    btn.frame = CGRectMake(0, 0, 84, 30);
    btn.backgroundColor = [UIColor colorWithRed:0.12 green:0.16 blue:0.25 alpha:0.92];
    btn.layer.cornerRadius = 15;
    btn.layer.borderWidth = 1.2;
    btn.layer.borderColor = [UIColor colorWithRed:0.0 green:0.80 blue:1.0 alpha:0.85].CGColor;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [btn setTitle:@"👑 Teledark" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:vc action:@selector(teledarkOpenMenuAction:) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *teledarkItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    teledarkItem.tag = TELEDARK_NAV_TAG;

    if (vc.navigationItem.rightBarButtonItems.count > 0) {
        NSMutableArray *items = [vc.navigationItem.rightBarButtonItems mutableCopy];
        [items insertObject:teledarkItem atIndex:0];
        vc.navigationItem.rightBarButtonItems = items;
    } else if (vc.navigationItem.rightBarButtonItem) {
        vc.navigationItem.rightBarButtonItems = @[teledarkItem, vc.navigationItem.rightBarButtonItem];
    } else {
        vc.navigationItem.rightBarButtonItem = teledarkItem;
    }
}

#pragma mark - Внедрение карточки надетого NFT в профиль (PeerInfo)

static void injectPeerInfoWornGiftCard(UIViewController *vc) {
    if (!vc.isViewLoaded || !vc.view) return;

    UIView *existing = [vc.view viewWithTag:77705];
    if (existing) {
        [existing removeFromSuperview];
    }

    ChimeraStore *s = [ChimeraStore shared];
    NSDictionary *worn = [s currentWornGift];

    CGFloat screenW = vc.view.bounds.size.width;
    if (screenW < 100) screenW = [UIScreen mainScreen].bounds.size.width;

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16, 68, screenW - 32, 66)];
    card.tag = 77705;
    card.backgroundColor = [UIColor colorWithRed:0.09 green:0.12 blue:0.19 alpha:0.96];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1.2;
    card.layer.borderColor = [UIColor colorWithRed:0.0 green:0.80 blue:1.0 alpha:0.8].CGColor;
    card.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UILabel *badgeLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 8, card.bounds.size.width - 28, 16)];
    badgeLbl.text = worn ? @"👑 НАДЕТ В ПРОФИЛЕ (CHIMERA NFT)" : @"🎁 CHIMERA NFT: НАДЕТЬ ПОДАРОК В ПРОФИЛЬ";
    badgeLbl.font = [UIFont boldSystemFontOfSize:10];
    badgeLbl.textColor = [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:1.0];
    badgeLbl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [card addSubview:badgeLbl];

    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 26, card.bounds.size.width - 100, 22)];
    if (worn) {
        titleLbl.text = [NSString stringWithFormat:@"%@ #%@ · %@", worn[@"title"], worn[@"number"], worn[@"pattern"] ?: @"Unique"];
        titleLbl.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    } else {
        titleLbl.text = @"Нажмите, чтобы выдать и надеть NFT";
        titleLbl.textColor = [UIColor whiteColor];
    }
    titleLbl.font = [UIFont boldSystemFontOfSize:14];
    titleLbl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [card addSubview:titleLbl];

    UIButton *actionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    actionBtn.frame = CGRectMake(card.bounds.size.width - 94, 18, 82, 30);
    actionBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    actionBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.65 blue:0.95 alpha:0.9];
    actionBtn.layer.cornerRadius = 12;
    [actionBtn setTitle:worn ? @"Сменить ➔" : @"Выбрать ➔" forState:UIControlStateNormal];
    actionBtn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [actionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [actionBtn addTarget:vc action:@selector(teledarkOpenMenuAction:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:actionBtn];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:vc action:@selector(teledarkOpenMenuAction:)];
    [card addGestureRecognizer:tap];

    [vc.view addSubview:card];
}

#pragma mark - Внедрение баннера в экраны «Купить / Отправить подарок» (Gift Screens)

static void injectGiftScreenChimeraBanner(UIViewController *vc) {
    if (!vc.isViewLoaded || !vc.view) return;
    if ([vc.view viewWithTag:77708]) return;

    CGFloat screenW = vc.view.bounds.size.width;
    if (screenW < 100) screenW = [UIScreen mainScreen].bounds.size.width;

    UIView *banner = [[UIView alloc] initWithFrame:CGRectMake(12, 10, screenW - 24, 48)];
    banner.tag = 77708;
    banner.backgroundColor = [UIColor colorWithRed:0.10 green:0.13 blue:0.22 alpha:0.98];
    banner.layer.cornerRadius = 14;
    banner.layer.borderWidth = 1.3;
    banner.layer.borderColor = [UIColor colorWithRed:0.0 green:0.85 blue:1.0 alpha:0.9].CGColor;
    banner.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 6, banner.bounds.size.width - 110, 36)];
    lbl.text = @"👑 CHIMERA NFT\nКупить любые NFT в свой профиль";
    lbl.numberOfLines = 2;
    lbl.font = [UIFont boldSystemFontOfSize:11];
    lbl.textColor = [UIColor whiteColor];
    lbl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [banner addSubview:lbl];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(banner.bounds.size.width - 95, 9, 85, 30);
    btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.75 blue:1.0 alpha:1.0];
    btn.layer.cornerRadius = 12;
    [btn setTitle:@"В маркет ➔" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:vc action:@selector(teledarkOpenMenuAction:) forControlEvents:UIControlEventTouchUpInside];
    [banner addSubview:btn];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:vc action:@selector(teledarkOpenMenuAction:)];
    [banner addGestureRecognizer:tap];

    [vc.view addSubview:banner];
    [vc.view bringSubviewToFront:banner];
}

#pragma mark - Хуки интерфейса и UIViewController

static void (*orig_viewDidAppear)(UIViewController *, SEL, BOOL);
static void hook_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);

    // 1. УБИРАЕМ ВСЕ ПЛАВАЮЩИЕ КНОПКИ С ЭКРАНА (по требованию пользователя)
    UIWindow *win = [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].windows.firstObject;
    if (win) {
        UIView *oldPill = [win viewWithTag:CHIMERA_FLOATING_TAG];
        if (oldPill) {
            [oldPill removeFromSuperview];
        }
    }

    NSString *className = NSStringFromClass([self class]);

    // 2. Интеграция в экраны «Купить / Отправить подарок»
    if ([className containsString:@"Gift"] || 
        [className containsString:@"AddGift"] || 
        [className containsString:@"GiftStore"] ||
        [className containsString:@"GiftView"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            injectGiftScreenChimeraBanner(self);
            ensureTeledarkNavButton(self);
        });
    }

    // 3. Интеграция в экран профиля (надетый NFT подарок)
    if ([className containsString:@"PeerInfo"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            injectPeerInfoWornGiftCard(self);
            ensureTeledarkNavButton(self);
        });
    }

    // 4. Внедряем нативную кнопку в Navigation Bar
    if ([className containsString:@"Settings"] || 
        [className containsString:@"ChatList"] ||
        [className containsString:@"TabController"] ||
        [className containsString:@"Root"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ensureTeledarkNavButton(self);
        });
    }

    // 5. Добавляем жест 2 пальцами дважды тапнуть по экрану (невидимый быстрый вызов меню)
    if (win && ![win viewWithTag:99901]) {
        UIView *flag = [[UIView alloc] initWithFrame:CGRectZero];
        flag.tag = 99901;
        [win addSubview:flag];

        UITapGestureRecognizer *twoFinger = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(teledarkOpenMenuAction:)];
        twoFinger.numberOfTouchesRequired = 2;
        twoFinger.numberOfTapsRequired = 2;
        twoFinger.cancelsTouchesInView = NO;
        [win addGestureRecognizer:twoFinger];
    }
}

#pragma mark - Универсальные хуки текста (подмена отображения Stars, Premium и Username)

static void (*orig_UILabel_setText)(UILabel *, SEL, NSString *);
static void hook_UILabel_setText(UILabel *self, SEL _cmd, NSString *text) {
    if (text && [text isKindOfClass:[NSString class]]) {
        ChimeraStore *s = [ChimeraStore shared];
        if ([text containsString:@"Stars"] || [text containsString:@"звёзд"] || [text containsString:@"звезды"]) {
            if ([text isEqualToString:@"0 Stars"] || [text isEqualToString:@"0 звёзд"] || [text isEqualToString:@"Telegram Stars"]) {
                text = [NSString stringWithFormat:@"⭐️ %lld Stars", s.starsBalance];
            }
        }
    }
    orig_UILabel_setText(self, _cmd, text);
}

static void (*orig_UILabel_setAttributedText)(UILabel *, SEL, NSAttributedString *);
static void hook_UILabel_setAttributedText(UILabel *self, SEL _cmd, NSAttributedString *attrText) {
    if (attrText && [attrText isKindOfClass:[NSAttributedString class]]) {
        NSString *str = attrText.string;
        ChimeraStore *s = [ChimeraStore shared];
        if ([str containsString:@"0 Stars"] || [str isEqualToString:@"0 звёзд"] || [str isEqualToString:@"Telegram Stars"]) {
            NSString *rep = [NSString stringWithFormat:@"⭐️ %lld Stars", s.starsBalance];
            NSDictionary *attrs = attrText.length > 0 ? [attrText attributesAtIndex:0 effectiveRange:NULL] : nil;
            attrText = [[NSAttributedString alloc] initWithString:rep attributes:attrs];
        }
    }
    if (orig_UILabel_setAttributedText) {
        orig_UILabel_setAttributedText(self, _cmd, attrText);
    }
}

static void (*orig_ImmediateTextNode_setAttributedText)(id, SEL, NSAttributedString *);
static void hook_ImmediateTextNode_setAttributedText(id self, SEL _cmd, NSAttributedString *attrText) {
    if (attrText && [attrText isKindOfClass:[NSAttributedString class]]) {
        NSString *str = attrText.string;
        ChimeraStore *s = [ChimeraStore shared];
        if ([str containsString:@"0 Stars"] || [str isEqualToString:@"0 звёзд"] || [str isEqualToString:@"Telegram Stars"]) {
            NSString *rep = [NSString stringWithFormat:@"⭐️ %lld Stars", s.starsBalance];
            NSDictionary *attrs = attrText.length > 0 ? [attrText attributesAtIndex:0 effectiveRange:NULL] : nil;
            attrText = [[NSAttributedString alloc] initWithString:rep attributes:attrs];
        }
    }
    if (orig_ImmediateTextNode_setAttributedText) {
        orig_ImmediateTextNode_setAttributedText(self, _cmd, attrText);
    }
}

__attribute__((constructor))
static void initializeExteraChimera() {
    NSLog(@"[Teledark/Chimera] Твик загружен: Нативная кнопка в Navigation Bar + Карточка в профиле + Маркет Fake NFT + Баланс + Premium!");

    // 1. Хук UIViewController viewDidAppear
    Class vcClass = [UIViewController class];
    if (vcClass) {
        Method m = class_getInstanceMethod(vcClass, @selector(viewDidAppear:));
        if (m) {
            orig_viewDidAppear = (void (*)(UIViewController *, SEL, BOOL))method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_viewDidAppear);
        }
    }

    // 2. Хук UILabel setText & setAttributedText для отображения накрученных Stars и Premium
    Class labelClass = [UILabel class];
    if (labelClass) {
        Method mText = class_getInstanceMethod(labelClass, @selector(setText:));
        if (mText) {
            orig_UILabel_setText = (void (*)(UILabel *, SEL, NSString *))method_getImplementation(mText);
            method_setImplementation(mText, (IMP)hook_UILabel_setText);
        }
        Method mAttr = class_getInstanceMethod(labelClass, @selector(setAttributedText:));
        if (mAttr) {
            orig_UILabel_setAttributedText = (void (*)(UILabel *, SEL, NSAttributedString *))method_getImplementation(mAttr);
            method_setImplementation(mAttr, (IMP)hook_UILabel_setAttributedText);
        }
    }

    // 3. Хук ImmediateTextNode setAttributedText (Telegram AsyncDisplayKit)
    Class textNodeClass = NSClassFromString(@"_TtC7Display17ImmediateTextNode");
    if (textNodeClass) {
        Method mNode = class_getInstanceMethod(textNodeClass, @selector(setAttributedText:));
        if (mNode) {
            orig_ImmediateTextNode_setAttributedText = (void (*)(id, SEL, NSAttributedString *))method_getImplementation(mNode);
            method_setImplementation(mNode, (IMP)hook_ImmediateTextNode_setAttributedText);
        }
    }
}
