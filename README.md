# AHAlertView

## Overview

`AHAlertView` is a powerful, block-based alternative to UIKit's `UIAlertView`. It has the following attractive features:

 1. Block-based button events - no more messy delegate code
 2. `UIAppearance` conformance to allow easy skinning of all elements
 3. Dramatic presentation and dismissal animations (tumble, fade, zoom, etc.)

## Usage Examples

Showing an alert is as simple as creating an alert, adding a button, and calling `show`:

    AHAlertView *alert = [[AHAlertView alloc] initWithTitle:@"Hello, World!" message:@"I'm an alert view!"];
    [alert setCancelButtonTitle:@"Dismiss" block:nil];
    [alert show];

If a total of two buttons are added, the alert view will lay them out side-by-side:

![Two button side-by-side layout example](https://dl.dropbox.com/u/13103695/Screenshots/AHAlertView-TwoButtons.png)

    AHAlertView *alert = [[AHAlertView alloc] initWithTitle:@"Enter Password" message:@"This is a message that might prompt you to do something."];
    [alert setCancelButtonTitle:@"Cancel" block:nil];
    [alert addButtonWithTitle:@"OK" block:nil];
    [alert show];

You can use an alert view to prompt for user input, including secure text for password fields, etc.:

![Secure text entry example](https://dl.dropbox.com/u/13103695/Screenshots/AHAlertView-SecureTextInput.png)

    AHAlertView *alert = [[AHAlertView alloc] initWithTitle:@"Enter Password" message:@"user@example.com"];
    alert.alertViewStyle = AHAlertViewStyleSecureTextInput;
    [alert setCancelButtonTitle:@"Cancel" block:^{
    	NSLog(@"User canceled the alert instead of entering their password.");
    }];
    [alert addButtonWithTitle:@"OK" block:^{
    	NSLog(@"User entered the password: %@", [alert textFieldAtIndex:0].text);
    }];
    [alert show];

You can use the block you pass in with the button title to perform any action, including setting a custom dismissal animation based on which button was touched:

<video width="320" height="480" controls="controls">
  <source src="https://dl.dropbox.com/u/13103695/Screenshots/AHAlertView-Tumble.mov" type="video/quicktime" />
  Your browser does not support the video tag.
</video>

    [alert setCancelButtonTitle:@"Cancel" block:^{
	    alert.dismissalStyle = AHAlertViewDismissalStyleTumble;
    }];

## TODO

 - I think we can all agree a little more documentation would be nice.
 - Indeterminate progress style, possibly a determinate one as well.
 - Better button layout code
