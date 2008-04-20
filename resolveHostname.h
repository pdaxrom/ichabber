/*
 *  resolveHostname.h
 *  iNG
 *
 *  Created by Will Dietz on 3/17/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/NSString.h>

/* 
 * ===  FUNCTION  ======================================================================
 *         Name:  resolveHostname
 *  Description:  attempts to resolve the hostname using apple's API.  returns string containing the ip if successful, else nil.
 * =====================================================================================
 */
NSString * resolveHostname( NSString * name );
