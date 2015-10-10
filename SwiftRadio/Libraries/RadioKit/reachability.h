/*
 *  reachability.h
 *  RadioParadise
 *
 *  Created by Brian Stormont on 11/23/08.
 *  Copyright 2008 Stormy Productions. All rights reserved.
 *
 */


#import <UIKit/UIKit.h>
#import <SystemConfiguration/SCNetworkReachability.h>


enum {
	REACH_BY_WIFI = 1,
	REACH_BY_CELL
};


extern unsigned int isNetReachable(NSString *url);