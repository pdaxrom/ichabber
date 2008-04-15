#import "EyeCandy.h"

@implementation EyeCandy

- (void) showStandardAlert:(NSString *)title closeBtnTitle:(NSString *)closeTitle withError:(NSError *)error
{
	alertButton = [NSArray arrayWithObjects:closeTitle,nil];
	alert = [[UIAlertSheet alloc] initWithTitle:title buttons:alertButton defaultButtonIndex:0 delegate:self context:nil];
	[alert setBodyText: [error localizedDescription]];
	[alert popupAlertAnimated: TRUE];
}

- (void) showStandardAlertWithString:(NSString *)title closeBtnTitle:(NSString *)closeTitle withError:(NSString *)error
{
	alertButton = [NSArray arrayWithObjects:closeTitle,nil];
	alert = [[UIAlertSheet alloc] initWithTitle:title buttons:alertButton defaultButtonIndex:0 delegate:self context:nil];
	[alert setBodyText: error];
	[alert popupAlertAnimated: TRUE];
}

- (void) showAlertWithTitle:(NSString *)title closeBtnTitle:(NSString *)closeTitle withText:(NSString *)string andStyle:(int) style
{
	alertButton = [NSArray arrayWithObjects:closeTitle,nil];
	alert = [[UIAlertSheet alloc] initWithTitle:title buttons:alertButton defaultButtonIndex:0 delegate:self context:nil];
	[alert setBodyText: string];
	[alert setAlertSheetStyle: style];
	[alert popupAlertAnimated: TRUE];
}

- (void) showAlertYesNoWithTitle:(NSString *)title withText:(NSString *)string andStyle:(int) style andDelegate:(id) delegate andContext:(id) context
{
	//alertButton = [NSArray arrayWithObjects:closeTitle,nil];
	alert = [[ UIAlertSheet alloc ] initWithFrame: CGRectMake(0, 240, 320, 240) ];
	[alert setTitle: title];
	[alert setBodyText: string];
	[alert setContext: context];
	[alert addButtonWithTitle:NSLocalizedString(@"YES", @"YES")];
	[alert setDestructiveButton: [alert addButtonWithTitle:NSLocalizedString(@"NO", @"NO")]];
	[alert setDelegate: delegate];
	[alert setAlertSheetStyle: style];
	[alert popupAlertAnimated: TRUE];
}

- (void) alertSheet: (UIAlertSheet*)sheet buttonClicked:(int)button
{
	NSLog(@"alert butt %d\n", button);
	[sheet dismissAnimated: TRUE];
}

- (void)showProgressHUD:(NSString *)label withWindow:(UIWindow *)w withView:(UIView *)v withRect:(struct CGRect)rect
{
	progress = [[UIProgressHUD alloc] initWithWindow: w];
	[progress setText: label];
	[progress drawRect: rect];
	[progress show: YES];
	
	[v addSubview:progress];
}

- (void)hideProgressHUD
{
	[progress show: NO];
	[progress removeFromSuperview];
}

@end