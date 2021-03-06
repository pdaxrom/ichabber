#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesDeleteTableCell.h>
#import <UIKit/UISwitchControl.h>
#import <UIKit/UIControl.h>

#import "EyeCandy.h"
#import "version.h"

#define PATH			[@"~/Library/iChabber/" stringByExpandingTildeInPath]
#define GLOBAL_PREF_PATH	[NSString stringWithFormat: @"%@/%@", PATH, @"iChabber.plist"]
#define USER_PREF_PATH(user)	[NSString stringWithFormat: @"%@/iChabber_%@.plist", PATH, user]

#define CFGDIR  "Library/iChabber/"
#define CFGNAME "config"

@interface MyPrefs : UIView {
    EyeCandy *eyeCandy; 
    
    UIPreferencesTable *table;
    UIPreferencesTextTableCell *_username;
    UIPreferencesTextTableCell *_password;
    UIPreferencesTextTableCell *_server;
    UIPreferencesTextTableCell *_port;
    UIPreferencesControlTableCell *_use_ssl;
    UIPreferencesControlTableCell *_use_ssl_verify;

    UIPreferencesControlTableCell *_use_gtalk;

    UIPreferencesTextTableCell *_proxy_host;
    UIPreferencesTextTableCell *_proxy_port;
    UIPreferencesTextTableCell *_proxy_username;
    UIPreferencesTextTableCell *_proxy_password;
    
    UIPreferencesControlTableCell *_proxy_enable;

    UIPreferencesControlTableCell *_sound_enable;
    UIPreferencesControlTableCell *_vibro_enable;

    UIPreferencesControlTableCell *_offline_users;
    
    NSString *dirPath;
}

- (id)initPrefs;
- (void)reloadData;

- (void)loadConfig;
- (void)saveConfig;

- (NSString *) getUsername;
- (NSString *) getPassword;
- (NSString *) getResource;
- (NSString *) getServer;
- (int) getPort;
- (int) useSSL;
- (int) useSSLVerify;

- (int) useProxy;
- (NSString *) getProxyServer;
- (int) getProxyPort;
- (NSString *) getProxyUser;
- (NSString *) getProxyPassword;

- (int) useSound;
- (int) useVibro;
- (int) offlineUsers;

- (void)tableRowSelected:(NSNotification *)notification;

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table;
- (int)preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group;
- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForGroup:(int)group;
- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForRow:(int)row inGroup:(int)group;

- (void)dealloc;

@end
