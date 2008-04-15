//
//  Notifications.m
//  MobileChatApp
//
//  Created by Shaun Harrison on 9/22/07.
//  Copyright 2007 twenty08. All rights reserved.
//

#import "Notifications.h"
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>

extern void * _CTServerConnectionCreate(CFAllocatorRef, int (*)(void *, CFStringRef, CFDictionaryRef, void *), int *);
extern int _CTServerConnectionSetVibratorState(int *, void *, int, float, float, float, float);

static id sharedInst;
static NSRecursiveLock *lock;

int vibratecallback(void *connection, CFStringRef string, CFDictionaryRef dictionary, void *data) {
	return 1;
}

@implementation Notifications
    + (void) initialize {
	sharedInst = lock = nil;
    }

    + (id) sharedInstance {
    [lock lock];
	if (!sharedInst) {
		sharedInst = [[[self class] alloc] init];		
	}
	[lock unlock];
    
	return sharedInst;
    }

    - (id) init {
	id parent = [super init];
	[self initSounds];
	return parent;
    }

    - (void) initSounds {
	NSError* error;
	if(!_avc) {
		_avc = [[AVController alloc] init];
		[_avc setDelegate:self];
		[_avc setVibrationEnabled:YES];	

		_soundIn = [[AVItem alloc] initWithPath: 
			[[NSBundle mainBundle] pathForResource:@"received" 
			ofType:@"aiff" inDirectory:@"/"] error:&error];

		_soundOut = [[AVItem alloc] initWithPath: 
			[[NSBundle mainBundle] pathForResource:@"sent" 
			ofType:@"aiff" inDirectory:@"/"] error:&error];

		[_soundIn setVolume: 100];
		[_soundOut setVolume: 100];
		
		[_avc retain];
		[_soundIn retain];
		[_soundOut retain];
	}
	_isPlaying = NO;
	_isVibrating = NO;
    }

    - (void) setApp: (id) app {
	_app = app;
    }

    - (void) playSound: (int) type {
	if(_isPlaying == NO) {
		if(type == 1) {
			// Incoming
			[NSThread detachNewThreadSelector:@selector(play:) toTarget:self withObject:_soundIn];
		} else {
			// Outgoing
			[NSThread detachNewThreadSelector:@selector(play:) toTarget:self withObject:_soundOut];
		}
		_isPlaying = YES;
	}
    }

    - (void) play: (AVItem*) sound {
	NSAutoreleasePool* p = [[NSAutoreleasePool alloc] init];
	[_avc retain];
	[sound retain];
	{
	    NSLog(@"Notifications> play sound");
	    NSError* error;
	    [_avc setCurrentItem:sound];
	    [_avc play:&error];
	}
	_isPlaying = NO;
	[sound release];
	[_avc release];
	[p release];
    }

    - (void) vibrate {
	{
		NSLog(@"Vibrate...");
		_isVibrating = YES;
		[NSThread detachNewThreadSelector:@selector(doVibrate) toTarget:self withObject:nil];
	}
    }

    - (void) doVibrate {
	NSAutoreleasePool* p = [[NSAutoreleasePool alloc] init];
	int x;
	void* connection = _CTServerConnectionCreate(kCFAllocatorDefault, &vibratecallback, &x);
	_CTServerConnectionSetVibratorState(&x, connection, 3, 10.0, 10.0, 10.0, 10.0);
	//clock_t now = clock();
	//while (clock() - now < (CLOCKS_PER_SEC >> 1)) { }
	usleep(500000);
	_CTServerConnectionSetVibratorState(&x, connection, 0, 10.0, 10.0, 10.0, 10.0);
	_isVibrating = NO;
	[p release];
    }

@end
