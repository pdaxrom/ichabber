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

#define CFGDIR  "Library/iChabber/"
#define CFGNAME "config"

@interface MyPrefs : UIView {
    UIPreferencesTable *table;
    UIPreferencesTextTableCell *_username;
    UIPreferencesTextTableCell *_password;

    UIPreferencesTextTableCell *_proxy_host;
    UIPreferencesTextTableCell *_proxy_port;
    UIPreferencesTextTableCell *_proxy_username;
    UIPreferencesTextTableCell *_proxy_password;
    
    UIPreferencesControlTableCell *_proxy_enable;
    
    NSString *dirPath;
}

- (id)initWithFrame:(struct CGRect)frame;
- (void)reloadData;

- (void)loadConfig;
- (void)saveConfig;

- (NSString *) getConfigDir;

- (NSString *) getUsername;
- (NSString *) getPassword;

- (int) useProxy;
- (NSString *) getProxyHost;
- (int) getProxyPort;
- (NSString *) getProxyUser;
- (NSString *) getProxyPassword;

- (void)tableRowSelected:(NSNotification *)notification;

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table;
- (int)preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group;
- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForGroup:(int)group;
- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForRow:(int)row inGroup:(int)group;

- (void)dealloc;

@end
