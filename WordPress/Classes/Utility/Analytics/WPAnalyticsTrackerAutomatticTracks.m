#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPAccount.h"
#import "Blog.h"
#ifdef KEYSTONE
#import "Keystone-Swift.h"
#else
#import "WordPress-Swift.h"
#endif
@import AutomatticTracks;
@import AutomatticTracksEvents;

@interface WPAnalyticsTrackerAutomatticTracks ()

@property (nonatomic, strong) TracksContextManager *contextManager;
@property (nonatomic, strong) TracksService *tracksService;
@property (nonatomic, strong) NSDictionary *userProperties;
@property (nonatomic, strong) NSString *anonymousID;
@property (nonatomic, strong) NSString *loggedInID;

@end

@implementation WPAnalyticsTrackerAutomatticTracks

@synthesize loggedInID = _loggedInID;
@synthesize anonymousID = _anonymousID;

- (instancetype)init {
    return [self initWithEventNamePrefix:[WPAnalytics eventNamePrefix] platform:[WPAnalytics explatPlatform]];
}

- (instancetype)initWithEventNamePrefix:(NSString *)eventNamePrefix platform:(NSString *)platform
{
    self = [super init];
    if (self) {
        _contextManager = [TracksContextManager new];
        _tracksService = [[TracksService alloc] initWithContextManager:_contextManager];
        _tracksService.eventNamePrefix = eventNamePrefix;
        _tracksService.platform = platform;
    }
    return self;
}

- (void)track:(WPAnalyticsStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    TracksEventPair *eventPair = [[self class] eventPairForStat:stat];
    if (!eventPair) {
        DDLogInfo(@"WPAnalyticsStat not supported by WPAnalyticsTrackerAutomatticTracks: %@", @(stat));
        return;
    }

    NSMutableDictionary *mergedProperties = [NSMutableDictionary new];

    [mergedProperties addEntriesFromDictionary:eventPair.properties];
    [mergedProperties addEntriesFromDictionary:properties];

    [self trackString:eventPair.eventName withProperties:mergedProperties];
}

- (void)trackString:(NSString *)event
{
    [self trackString:event withProperties:nil];
}

- (void)trackString:(NSString *)event withProperties:(NSDictionary *)properties {
    if (properties == nil) {
        DDLogInfo(@"🔵 Tracked: %@", event);
    } else {
        NSArray<NSString *> *propertyKeys = [[properties allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        NSString *propertiesDescription = [[propertyKeys wp_map:^NSString *(NSString *key) {
            return [NSString stringWithFormat:@"%@: %@", key, properties[key]];
        }] componentsJoinedByString:@", "];
        DDLogInfo(@"🔵 Tracked: %@ <%@>", event, propertiesDescription);
    }

    [self.tracksService trackEventName:event withCustomProperties:properties];
}

- (void)beginSession
{
    if (self.loggedInID.length > 0) {
        [self.tracksService switchToAuthenticatedUserWithUsername:self.loggedInID userID:nil wpComToken:[WPAccount tokenForUsername:self.loggedInID] skipAliasEventCreation:YES];
    } else {
        [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
    }

    [self refreshMetadata];
}

- (void)clearQueuedEvents
{
    [self.tracksService clearQueuedEvents];
}

- (void)refreshMetadata
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    __block NSUInteger blogCount;
    __block NSString *username;
    __block NSNumber *userID;
    __block NSString *emailAddress;
    __block BOOL accountPresent = NO;
    __block BOOL jetpackBlogsPresent = NO;
    __block WPAccount *account;

    [context performBlockAndWait:^{
        account = [WPAccount lookupDefaultWordPressComAccountInContext:context];

        blogCount = [Blog countInContext:context];
        jetpackBlogsPresent = [Blog hasAnyJetpackBlogsInContext:context];
        if (account != nil) {
            username = account.username;
            userID = nil;
            emailAddress = account.email;
            accountPresent = YES;
        }
    }];

    if ([[NSUUID alloc] initWithUUIDString:username]) {
        // User has authenticated but we're waiting for account details to sync.
        // Once details are synced this method will be called again with the actual
        // username. For now just exit without making changes.
        return;
    }

    BOOL dotcom_user = (accountPresent && username.length > 0);

    // The user "uses" gutenberg if it is enabled on any of their sites.
    __block BOOL gutenbergEnabled = NO;
    [account.blogs enumerateObjectsUsingBlock:^(Blog * _Nonnull blog, BOOL * _Nonnull stop) {
        if (blog.isGutenbergEnabled) {
            gutenbergEnabled = YES;
            *stop = YES;
        }
    }];

    NSMutableDictionary *userProperties = [NSMutableDictionary new];
    userProperties[@"app_scheme"] = WPAnalyticsTesting.appURLScheme ?: WordPressAppDelegate.appURLScheme;
    userProperties[@"platform"] = @"iOS";
    userProperties[@"dotcom_user"] = @(dotcom_user);
    userProperties[@"jetpack_user"] = @(jetpackBlogsPresent);
    userProperties[@"number_of_blogs"] = @(blogCount);
    userProperties[@"accessibility_voice_over_enabled"] = @(UIAccessibilityIsVoiceOverRunning());
    userProperties[@"is_rtl_language"] = @(UIApplication.sharedApplication.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft);
    userProperties[@"gutenberg_enabled"] = @(gutenbergEnabled);

    [self.tracksService.userProperties removeAllObjects];
    [self.tracksService.userProperties addEntriesFromDictionary:userProperties];

    // Tell the client what kind of user
    if (dotcom_user == YES) {
        if (self.loggedInID.length == 0) {
            // No previous username logged
            self.loggedInID = username;
            self.anonymousID = nil;

            [self.tracksService switchToAuthenticatedUserWithUsername:username userID:@"" wpComToken:[WPAccount tokenForUsername:username] skipAliasEventCreation:NO];
        } else if ([self.loggedInID isEqualToString:username]){
            // Username did not change from last refreshMetadata - just make sure Tracks client has it
            [self.tracksService switchToAuthenticatedUserWithUsername:username userID:@"" wpComToken:[WPAccount tokenForUsername:username] skipAliasEventCreation:YES];
        } else {
            // Username changed for some reason - switch back to anonymous first
            [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
            [self.tracksService switchToAuthenticatedUserWithUsername:username userID:@"" wpComToken:[WPAccount tokenForUsername:username] skipAliasEventCreation:NO];
            self.loggedInID = username;
            self.anonymousID = nil;
        }
    } else {
        // User is not authenticated, switch to an anonymous mode
        [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
        self.loggedInID = nil;
    }
}

#pragma mark - Private methods

- (NSString *)anonymousID
{
    if (_anonymousID == nil || _anonymousID.length == 0) {
        NSString *anonymousID = [[UserPersistentStoreFactory userDefaultsInstance] stringForKey:TracksUserDefaultsAnonymousUserIDKey];
        if (anonymousID == nil) {
            anonymousID = [[NSUUID UUID] UUIDString];
            [[UserPersistentStoreFactory userDefaultsInstance] setObject:anonymousID forKey:TracksUserDefaultsAnonymousUserIDKey];
        }
        
        _anonymousID = anonymousID;
    }
    
    return _anonymousID;
}

- (void)setAnonymousID:(NSString *)anonymousID
{
    _anonymousID = anonymousID;

    if (anonymousID == nil) {
        [[UserPersistentStoreFactory userDefaultsInstance] removeObjectForKey:TracksUserDefaultsAnonymousUserIDKey];
        return;
    }

    [[UserPersistentStoreFactory userDefaultsInstance] setObject:anonymousID forKey:TracksUserDefaultsAnonymousUserIDKey];
}

- (NSString *)loggedInID
{
    if (_loggedInID == nil || _loggedInID.length == 0) {
        NSString *loggedInID = [[UserPersistentStoreFactory userDefaultsInstance] stringForKey:TracksUserDefaultsLoggedInUserIDKey];
        if (loggedInID != nil) {
            _loggedInID = loggedInID;
        }
    }

    return _loggedInID;
}

- (void)setLoggedInID:(NSString *)loggedInID
{
    _loggedInID = loggedInID;

    if (loggedInID == nil) {
        [[UserPersistentStoreFactory userDefaultsInstance] removeObjectForKey:TracksUserDefaultsLoggedInUserIDKey];
        return;
    }

    [[UserPersistentStoreFactory userDefaultsInstance] setObject:loggedInID forKey:TracksUserDefaultsLoggedInUserIDKey];
}

@end
