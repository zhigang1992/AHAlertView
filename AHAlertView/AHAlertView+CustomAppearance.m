//
//  AHAlertView+CustomAppearance.m
//  AHAlertViewSample
//
//  Created by Kyle Fang on 2/25/13.
//  Copyright (c) 2013 Auerhaus Development, LLC. All rights reserved.
//

#import "AHAlertView+CustomAppearance.h"

@implementation AHAlertView (CustomAppearance)
+ (void)applyCustomAlertAppearance
{
	[[AHAlertView appearance] setContentInsets:UIEdgeInsetsMake(12, 18, 12, 18)];
	
	[[AHAlertView appearance] setBackgroundImage:[UIImage imageNamed:@"custom-dialog-background"]];
	
	UIEdgeInsets buttonEdgeInsets = UIEdgeInsetsMake(20, 8, 20, 8);
	
	UIImage *cancelButtonImage = [[UIImage imageNamed:@"custom-cancel-normal"]
								  resizableImageWithCapInsets:buttonEdgeInsets];
	UIImage *normalButtonImage = [[UIImage imageNamed:@"custom-button-normal"]
								  resizableImageWithCapInsets:buttonEdgeInsets];
    
	[[AHAlertView appearance] setCancelButtonBackgroundImage:cancelButtonImage
													forState:UIControlStateNormal];
	[[AHAlertView appearance] setButtonBackgroundImage:normalButtonImage
											  forState:UIControlStateNormal];
	
	[[AHAlertView appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      [UIFont boldSystemFontOfSize:18], UITextAttributeFont,
                                                      [UIColor whiteColor], UITextAttributeTextColor,
                                                      [UIColor blackColor], UITextAttributeTextShadowColor,
                                                      [NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset,
                                                      nil]];
    
	[[AHAlertView appearance] setMessageTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [UIFont systemFontOfSize:14], UITextAttributeFont,
                                                        [UIColor colorWithWhite:0.8 alpha:1.0], UITextAttributeTextColor,
                                                        [UIColor blackColor], UITextAttributeTextShadowColor,
                                                        [NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset,
                                                        nil]];
    
	[[AHAlertView appearance] setButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            [UIFont boldSystemFontOfSize:14], UITextAttributeFont,
                                                            [UIColor whiteColor], UITextAttributeTextColor,
                                                            [UIColor blackColor], UITextAttributeTextShadowColor,
                                                            [NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset,
                                                            nil]];
}
@end
