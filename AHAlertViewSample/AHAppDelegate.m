//
//  AHAppDelegate.m
//  AHAlertViewSample
//
//  Created by Warren Moore on 9/10/12.
//  Copyright (c) 2012 Auerhaus Development, LLC. All rights reserved.
//

#import "AHAppDelegate.h"
#import "AHAlertSampleViewController.h"

@implementation AHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	AHAlertSampleViewController *vc = [[AHAlertSampleViewController alloc] init];
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
