//
//  Notifications.h
//  MobileChatApp
//
//  Created by Shaun Harrison on 9/22/07.
//  Copyright 2007 twenty08. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIView-Geometry.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIAnimator.h>
#import <UIKit/UIAnimation.h>
#import <UIKit/UIAlphaAnimation.h>
#import <UIKit/UITransformAnimation.h>
#import <Celestial/AVController-AVController_Celeste.h>
#import <Celestial/AVController.h>
#import <Celestial/AVQueue.h>
#import <Celestial/AVItem.h>
#import <UIKit/UIHardware.h>


@class AVItem;
@class AVController;
@class AVQueue;

@interface Notifications : NSObject {
	id		_app;
	NSMutableArray*	_notices;
	NSMutableArray*	_ntitles;
	BOOL		_isPlaying;
	BOOL		_isVibrating;

	AVItem* 	_soundOut;
	AVItem* 	_soundIn;
	AVController* 	_avc;
}
+ (void) initialize;
+ (id) sharedInstance;
- (id) init;
- (void) initSounds;
- (void) setApp: (id) app;
- (void) playSound: (int) type;
- (void) play: (AVItem*) sound;
- (void) vibrate;
- (void) doVibrate;

@end
