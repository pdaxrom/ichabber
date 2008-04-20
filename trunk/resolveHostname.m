/*
 *  resolveHostname.m
 *  iNG
 *
 *  Created by Will Dietz on 3/17/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import "resolveHostname.h"
#import <Foundation/NSHost.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <dns_sd.h>
#import <sys/select.h>
#import <unistd.h>

#define DNS_RESOLV_TIMEOUT 5

/* 
 * ===  FUNCTION  ======================================================================
 *         Name:  resolveHostname
 *  Description:  attempts to resolve the hostname using apple's API.  returns string containing the ip if successful, else nil.
 * =====================================================================================
 */
NSString * resolveHostname( NSString * name )
{
	if ( name == nil )
	{
		return nil;
	}
	
	if ( inet_addr( [name UTF8String] ) != INADDR_NONE )
	{//it's already in a format we like/can use
		return name;
	}

	NSLog( @"Resolving for %@", name );
	DNSServiceErrorType error;
	DNSServiceRef service;

	error = DNSServiceQueryRecord( &service, 0 /*no flags*/,
		0 /*all network interfaces */,
		[name UTF8String],
		kDNSServiceType_A, /* we want the ipv4 addy */ 
		kDNSServiceClass_IN, /* internet */
		0, /* no callback */ 
		NULL /* no context */ );

	if ( error == kDNSServiceErr_NoError )//good so far...
	{
		int dns_sd_fd = DNSServiceRefSockFD(service);
		int nfds = dns_sd_fd + 1;
		fd_set readfds;
		struct timeval tv;
	
		FD_ZERO(&readfds);
		FD_SET(dns_sd_fd, &readfds);
		tv.tv_sec = DNS_RESOLV_TIMEOUT;
		tv.tv_usec = 0;
		NSString * ret = nil;
		int result = select(nfds, &readfds, (fd_set*)NULL, (fd_set*)NULL, &tv);
		if (result > 0)
		{
			if (FD_ISSET(dns_sd_fd, &readfds))
			{
				//remove this if you want to compile in c, not obj-c
				NSLog( @"resolved %@ to %@", name, [ [ NSHost hostWithName: name ] address ] );
				ret = [ NSString stringWithString: [ [ NSHost hostWithName: name] address ] ];
			}
		}
		//clean up and return accordingly
		DNSServiceRefDeallocate( service );
		return ret;

	}
	//clean up....
	DNSServiceRefDeallocate( service );

	NSLog( @"dns error: %d", error );

	return nil;
}

