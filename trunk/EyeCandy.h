#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIView.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIProgressHUD.h>

@interface EyeCandy : UIApplication {
	UIProgressHUD *progress;
	UIAlertSheet *alert;
	NSArray *alertButton;
	UIWindow *_window;
}

- (void) showStandardAlert:(NSString *)title closeBtnTitle:(NSString *)closeTitle withError:(NSError *)error;
- (void) showStandardAlertWithString:(NSString *)title closeBtnTitle:(NSString *)closeTitle withError:(NSString *)error;
- (void) showProgressHUD:(NSString *)label withWindow:(UIWindow *)w withView:(UIView *)v withRect:(struct CGRect)rect;
- (void) hideProgressHUD;

@end