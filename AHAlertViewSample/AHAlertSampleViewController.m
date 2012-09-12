//
//  AHAlertSampleViewController.m
//  AHAlertViewSample
//
//  Created by Warren Moore on 9/10/12.
//  Copyright (c) 2012 Auerhaus Development, LLC. All rights reserved.
//

#import "AHAlertSampleViewController.h"
#import "AHAlertView.h"

#define UIViewAutoresizingFlexibleMargins 45

@implementation AHAlertSampleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor grayColor];
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.frame = CGRectMake(85, 225, 143, 44);
	button.autoresizingMask = UIViewAutoresizingFlexibleMargins;

	[button setTitle:@"Show Alert View" forState:UIControlStateNormal];
	[button addTarget:self action:@selector(buttonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
}

- (IBAction)buttonWasPressed:(id)sender {
	NSString *message = @"Doyouthinkhesawus. Lorem ipsum perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium explicabo.";

	static NSInteger dismissalStyle = 1;
	
	AHAlertView *alert = [[AHAlertView alloc] initWithTitle:@"What Do You Call a Blind Dinosaur?" message:message];
	[alert setCancelButtonTitle:@"Cancel" block:^{
		alert.dismissalStyle = dismissalStyle;
		dismissalStyle = (dismissalStyle + 1) % 5;
	}];
	[alert addButtonWithTitle:@"OK" block:^{
		alert.dismissalStyle = dismissalStyle;
		dismissalStyle = (dismissalStyle + 1) % 5;
	}];
	[alert show];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
