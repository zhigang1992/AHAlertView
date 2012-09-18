//
//  AHAlertView.m
//  AHAlertViewSample
//
//	Copyright (C) 2012 Auerhaus Development, LLC
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "AHAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static const char * const kAHAlertViewButtonBlockKey = "AHAlertViewButtonBlock";

static const NSInteger kAHViewAutoresizingFlexibleSizeAndMargins =
	UIViewAutoresizingFlexibleLeftMargin |
	UIViewAutoresizingFlexibleWidth |
	UIViewAutoresizingFlexibleRightMargin |
	UIViewAutoresizingFlexibleTopMargin |
	UIViewAutoresizingFlexibleHeight |
	UIViewAutoresizingFlexibleBottomMargin;

static const CGFloat kAHAlertViewDefaultWidth = 276;
static const CGFloat kAHAlertViewMinimumHeight = 100;
static const CGFloat kAHAlertViewDefaultButtonHeight = 40;
static const CGFloat kAHAlertViewDefaultTextFieldHeight = 26;

CGFloat CGAffineTransformGetAbsoluteRotationAngleDifference(CGAffineTransform t1, CGAffineTransform t2)
{
	CGFloat dot = t1.a * t2.a + t1.c * t2.c;
	CGFloat n1 = sqrtf(t1.a * t1.a + t1.c * t1.c);
	CGFloat n2 = sqrtf(t2.a * t2.a + t2.c * t2.c);
	return acosf(dot / (n1 * n2));
}

#pragma mark - Internal interface

typedef void (^AHAnimationCompletionBlock)(BOOL); // Internal.
typedef void (^AHAnimationBlock)(); // Internal.

@interface AHAlertView () {
	BOOL hasLayedOut;
	BOOL keyboardIsVisible;
	BOOL isDismissing;
	CGFloat keyboardHeight;
	UIInterfaceOrientation previousOrientation;
}

@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, strong) UIWindow *previousKeyWindow;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UITextField *plainTextField;
@property (nonatomic, strong) UITextField *secureTextField;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *destructiveButton;
@property (nonatomic, strong) NSMutableArray *otherButtons;
@property (nonatomic, strong) NSMutableDictionary *buttonBackgroundImagesForControlStates;
@property (nonatomic, strong) NSMutableDictionary *cancelButtonBackgroundImagesForControlStates;
@property (nonatomic, strong) NSMutableDictionary *destructiveButtonBackgroundImagesForControlStates;
@end

#pragma mark - Implementation

@implementation AHAlertView

#pragma mark - Class life cycle methods

+ (void)initialize
{
	[self applySystemAlertAppearance];
}

+ (void)applySystemAlertAppearance {
	// Set up default values for all UIAppearance-compatible selectors
	
	[[self appearance] setBackgroundImage:[self alertBackgroundImage]];
	
	[[self appearance] setContentInsets:UIEdgeInsetsMake(16, 8, 8, 8)];
	
	[[self appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
		[UIFont boldSystemFontOfSize:17], UITextAttributeFont,
		[UIColor whiteColor], UITextAttributeTextColor,
		[UIColor blackColor], UITextAttributeTextShadowColor,
		[NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset,
		nil]];

	[[self appearance] setMessageTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
		[UIFont systemFontOfSize:15], UITextAttributeFont,
		[UIColor whiteColor], UITextAttributeTextColor,
		[UIColor blackColor], UITextAttributeTextShadowColor,
		[NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset,
		nil]];

	[[self appearance] setButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
		[UIFont boldSystemFontOfSize:17], UITextAttributeFont,
		[UIColor whiteColor], UITextAttributeTextColor,
		[UIColor blackColor], UITextAttributeTextShadowColor,
		[NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset,
		nil]];

	[[self appearance] setButtonBackgroundImage:[self normalButtonBackgroundImage] forState:UIControlStateNormal];
	
	[[self appearance] setCancelButtonBackgroundImage:[self cancelButtonBackgroundImage] forState:UIControlStateNormal];
}

#pragma mark - Instance life cycle methods

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
	CGRect frame = CGRectMake(0, 0, kAHAlertViewDefaultWidth, kAHAlertViewMinimumHeight);
	
	if((self = [super initWithFrame:frame]))
	{
		[super setBackgroundColor:[UIColor clearColor]];

		_title = title;
		_message = message;
		
		_presentationStyle = AHAlertViewPresentationStyleDefault;
		_dismissalStyle = AHAlertViewDismissalStyleDefault;

		previousOrientation = [[UIApplication sharedApplication] statusBarOrientation];

		_otherButtons = [NSMutableArray array];

		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(deviceOrientationChanged:)
													 name:UIDeviceOrientationDidChangeNotification
												   object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardFrameChanged:)
													 name:UIKeyboardWillShowNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardFrameChanged:)
													 name:UIKeyboardWillHideNotification
												   object:nil];
	}
	return self;
}

- (void)dealloc
{
	for(id button in _otherButtons)
		objc_setAssociatedObject(button, kAHAlertViewButtonBlockKey, nil, OBJC_ASSOCIATION_RETAIN);

	if(_cancelButton)
		objc_setAssociatedObject(_cancelButton, kAHAlertViewButtonBlockKey, nil, OBJC_ASSOCIATION_RETAIN);
	
	if(_destructiveButton)
		objc_setAssociatedObject(_destructiveButton, kAHAlertViewButtonBlockKey, nil, OBJC_ASSOCIATION_RETAIN);

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIDeviceOrientationDidChangeNotification
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillShowNotification
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillHideNotification
												  object:nil];

	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (UIButton *)buttonWithTitle:(NSString *)aTitle associatedBlock:(AHAlertViewButtonBlock)block {
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
	
	[button setTitle:aTitle forState:UIControlStateNormal];
	[button addTarget:self action:@selector(buttonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(button, kAHAlertViewButtonBlockKey, block, OBJC_ASSOCIATION_RETAIN);
	return button;
}

- (void)addButtonWithTitle:(NSString *)title block:(AHAlertViewButtonBlock)block {
	if(!self.otherButtons)
		self.otherButtons = [NSMutableArray array];
	
	UIButton *otherButton = [self buttonWithTitle:title associatedBlock:block];
	[self.otherButtons addObject:otherButton];
	[self addSubview:otherButton];
}

- (void)setDestructiveButtonTitle:(NSString *)title block:(AHAlertViewButtonBlock)block {
	if(title) {
		self.destructiveButton = [self buttonWithTitle:title associatedBlock:block];
		[self addSubview:self.destructiveButton];
	} else {
		[self.destructiveButton removeFromSuperview];
		self.destructiveButton = nil;
	}
}

- (void)setCancelButtonTitle:(NSString *)title block:(AHAlertViewButtonBlock)block {
	if(title) {
		self.cancelButton = [self buttonWithTitle:title associatedBlock:block];
		[self addSubview:self.cancelButton];
	} else {
		[self.cancelButton removeFromSuperview];
		self.cancelButton = nil;
	}
}

- (void)setAlertViewStyle:(AHAlertViewStyle)alertViewStyle
{
	_alertViewStyle = alertViewStyle;

	// Cause text fields or other views to be instantiated lazily next time we lay out
	[self setNeedsLayout];
}

#pragma mark - Text field accessor

- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex
{
	[self ensureTextFieldsForCurrentAlertStyle];

	switch(self.alertViewStyle)
	{
		case AHAlertViewStyleLoginAndPasswordInput:
			if(textFieldIndex == 0)
				return self.plainTextField;
			else if(textFieldIndex == 1)
				return self.secureTextField;
			break;

		case AHAlertViewStylePlainTextInput:
			if(textFieldIndex == 0)
				return self.plainTextField;
			break;

		case AHAlertViewStyleSecureTextInput:
			if(textFieldIndex == 0)
				return self.secureTextField;
			break;

		default:
			break;
	}

	return nil;
}

#pragma mark - Appearance selectors

- (void)setButtonBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state
{
	if(!self.buttonBackgroundImagesForControlStates)
		self.buttonBackgroundImagesForControlStates = [NSMutableDictionary dictionary];
	
	[self.buttonBackgroundImagesForControlStates setObject:backgroundImage
													forKey:[NSNumber numberWithInteger:state]];
}

- (UIImage *)buttonBackgroundImageForState:(UIControlState)state
{
	return [self.buttonBackgroundImagesForControlStates objectForKey:[NSNumber numberWithInteger:state]];
}

- (void)setCancelButtonBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state
{
	if(!self.cancelButtonBackgroundImagesForControlStates)
		self.cancelButtonBackgroundImagesForControlStates = [NSMutableDictionary dictionary];

	[self.cancelButtonBackgroundImagesForControlStates setObject:backgroundImage
														  forKey:[NSNumber numberWithInteger:state]];
}

- (UIImage *)cancelButtonBackgroundImageForState:(UIControlState)state
{
	return [self.cancelButtonBackgroundImagesForControlStates objectForKey:[NSNumber numberWithInteger:state]];
}

- (void)setDestructiveButtonBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state
{
	if(!self.destructiveButtonBackgroundImagesForControlStates)
		self.destructiveButtonBackgroundImagesForControlStates = [NSMutableDictionary dictionary];
	
	[self.destructiveButtonBackgroundImagesForControlStates setObject:backgroundImage
															   forKey:[NSNumber numberWithInteger:state]];
}

- (UIImage *)destructiveButtonBackgroundImageForState:(UIControlState)state
{
	return [self.destructiveButtonBackgroundImagesForControlStates objectForKey:[NSNumber numberWithInteger:state]];
}

#pragma mark - Presentation and dismissal methods

- (void)show {
	[self showWithStyle:self.presentationStyle];
}

- (void)showWithStyle:(AHAlertViewPresentationStyle)style
{
	self.presentationStyle = style;
	
	[self setNeedsLayout];

	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	self.alertWindow = [[UIWindow alloc] initWithFrame:screenBounds];
	self.alertWindow.windowLevel = UIWindowLevelAlert;
	self.previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
	[self.alertWindow makeKeyAndVisible];

	UIImageView *dimView = [[UIImageView alloc] initWithFrame:self.alertWindow.bounds];
	dimView.image = [self backgroundGradientImageWithSize:self.alertWindow.bounds.size];
	dimView.userInteractionEnabled = YES;
	
	[self.alertWindow addSubview:dimView];
	[dimView addSubview:self];
	
	[self performPresentationAnimation];
}


- (void)dismiss {
	[self dismissWithStyle:self.dismissalStyle];
}

- (void)dismissWithStyle:(AHAlertViewDismissalStyle)style {
	self.dismissalStyle = style;
	isDismissing = YES;
	[self endEditing:YES];
	[self performDismissalAnimation];
}

- (void)buttonWasPressed:(UIButton *)sender {
	AHAlertViewButtonBlock block = objc_getAssociatedObject(sender, kAHAlertViewButtonBlockKey);
	if(block) block();
	
	[self dismissWithStyle:self.dismissalStyle];
}

#pragma mark - Presentation and dismissal animation utilities

- (void)performPresentationAnimation
{
	if(self.presentationStyle == AHAlertViewPresentationStylePop)
	{
		// This implementation was inspired by Jeff LaMarche's article on custom UIAlertViews. Thanks!
		// See: http://iphonedevelopment.blogspot.com/2010/05/custom-alert-views.html
		CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animation];
		bounceAnimation.duration = 0.3;
		bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		bounceAnimation.values = [NSArray arrayWithObjects:
								  [NSNumber numberWithFloat:0.01],
								  [NSNumber numberWithFloat:1.1],
								  [NSNumber numberWithFloat:0.9],
								  [NSNumber numberWithFloat:1.0],
								  nil];
		
		[self.layer addAnimation:bounceAnimation forKey:@"transform.scale"];
		
		CABasicAnimation *fadeInAnimation = [CABasicAnimation animation];
		fadeInAnimation.duration = 0.3;
		fadeInAnimation.fromValue = [NSNumber numberWithFloat:0];
		fadeInAnimation.toValue = [NSNumber numberWithFloat:1];
		[self.superview.layer addAnimation:fadeInAnimation forKey:@"opacity"];
	}
	else if(self.presentationStyle == AHAlertViewPresentationStyleFade)
	{
		self.superview.alpha = 0;
		
		[UIView animateWithDuration:0.3
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 self.superview.alpha = 1;
		 }
						 completion:nil];
	}
	else
	{
		// Views appear immediately when added
	}

	[[self textFieldAtIndex:0] becomeFirstResponder];
}

- (void)performDismissalAnimation {
	AHAnimationCompletionBlock completionBlock = ^(BOOL finished)
	{
		[self.superview removeFromSuperview];
		[self removeFromSuperview];

		[self.previousKeyWindow makeKeyWindow];
		self.alertWindow = nil;
		self.previousKeyWindow = nil;

		isDismissing = NO;
	};
	
	if(self.dismissalStyle == AHAlertViewDismissalStyleTumble)
	{
		[UIView animateWithDuration:0.6
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseIn
						 animations:^
		 {
			 CGPoint offset = CGPointMake(0, self.superview.bounds.size.height * 1.5);
			 offset = CGPointApplyAffineTransform(offset, self.transform);
			 self.transform = CGAffineTransformConcat(self.transform, CGAffineTransformMakeRotation(-M_PI_4));
			 self.center = CGPointMake(self.center.x + offset.x, self.center.y + offset.y);
			 self.superview.alpha = 0;
		 }
						 completion:completionBlock];
	}
	else if(self.dismissalStyle == AHAlertViewDismissalStyleFade)
	{
		[UIView animateWithDuration:0.25
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^
		 {
			 self.superview.alpha = 0;
		 }
						 completion:completionBlock];
	}
	else if(self.dismissalStyle == AHAlertViewDismissalStyleZoomDown)
	{
		[UIView animateWithDuration:0.3
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseIn
						 animations:^
		 {
			 self.transform = CGAffineTransformConcat(self.transform, CGAffineTransformMakeScale(0.01, 0.01));
			 self.superview.alpha = 0;
		 }
						 completion:completionBlock];
	}
	else if(self.dismissalStyle == AHAlertViewDismissalStyleZoomOut)
	{
		[UIView animateWithDuration:0.25
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 self.transform = CGAffineTransformConcat(self.transform, CGAffineTransformMakeScale(10, 10));
			 self.superview.alpha = 0;
		 }
						 completion:completionBlock];
	}
	else
	{
		completionBlock(YES);
	}
}

#pragma mark - Layout calculation methods

- (void)layoutSubviews {
	[super layoutSubviews];

	CGRect boundingRect = self.bounds;
	boundingRect = UIEdgeInsetsInsetRect(boundingRect, self.contentInsets);
	boundingRect.size.height = FLT_MAX;

	boundingRect = [self layoutTitleLabelWithinRect:boundingRect];
	boundingRect = [self layoutMessageLabelWithinRect:boundingRect];
	boundingRect = [self layoutTextFieldsWithinRect:boundingRect];
	boundingRect = [self layoutButtonsWithinRect:boundingRect];

	CGRect newBounds = CGRectMake(0, 0, self.bounds.size.width, boundingRect.origin.y + self.contentInsets.bottom);
	self.bounds = newBounds;

	[self rotateToMatchInterfaceOrientation];

	[self layoutBackgroundImageView];
}

- (CGRect)layoutTitleLabelWithinRect:(CGRect)boundingRect
{
	const CGFloat kTitleLabelBottomMargin = 8;

	if(!self.titleLabel && self.title)
		self.titleLabel = [self addLabelAsSubview];

	[self applyTextAttributes:self.titleTextAttributes toLabel:self.titleLabel];
	self.titleLabel.text = self.title;
	CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font
										constrainedToSize:boundingRect.size
											lineBreakMode:UILineBreakModeWordWrap];
	self.titleLabel.frame = CGRectMake(boundingRect.origin.x, boundingRect.origin.y,
									   boundingRect.size.width, titleSize.height);

	CGFloat margin = (titleSize.height > 0) ? kTitleLabelBottomMargin : 0;

	boundingRect.origin.y = boundingRect.origin.y + titleSize.height + margin;
	return boundingRect;
}

- (CGRect) layoutMessageLabelWithinRect:(CGRect)boundingRect
{
	const CGFloat kMessageLabelBottomMargin = 16;

	if(!self.messageLabel && self.message)
		self.messageLabel = [self addLabelAsSubview];

	[self applyTextAttributes:self.messageTextAttributes toLabel:self.messageLabel];
	self.messageLabel.text = self.message;
	CGSize messageSize = [self.messageLabel.text sizeWithFont:self.messageLabel.font
											constrainedToSize:boundingRect.size
												lineBreakMode:UILineBreakModeWordWrap];
	self.messageLabel.frame = CGRectMake(boundingRect.origin.x, boundingRect.origin.y,
										 boundingRect.size.width, messageSize.height);

	CGFloat margin = (messageSize.height > 0) ? kMessageLabelBottomMargin : 0;

	boundingRect.origin.y = boundingRect.origin.y + messageSize.height + margin;
	return boundingRect;
}

- (void)ensureTextFieldsForCurrentAlertStyle
{
	BOOL wantsPlainTextField = (self.alertViewStyle == AHAlertViewStylePlainTextInput ||
								self.alertViewStyle == AHAlertViewStyleLoginAndPasswordInput);
	BOOL wantsSecureTextField = (self.alertViewStyle == AHAlertViewStyleSecureTextInput ||
								 self.alertViewStyle == AHAlertViewStyleLoginAndPasswordInput);

	if(!wantsPlainTextField)
	{
		[self.plainTextField removeFromSuperview];
		self.plainTextField = nil;
	}
	else if(wantsPlainTextField && !self.plainTextField)
	{
		self.plainTextField = [[UITextField alloc] initWithFrame:CGRectZero];
		self.plainTextField.backgroundColor = [UIColor whiteColor];
		self.plainTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
		self.plainTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
		self.plainTextField.returnKeyType = UIReturnKeyNext;
		self.plainTextField.borderStyle = UITextBorderStyleLine;
		self.plainTextField.placeholder = @"Username";
		[self addSubview:self.plainTextField];
	}

	if(!wantsSecureTextField)
	{
		[self.secureTextField removeFromSuperview];
		self.secureTextField = nil;
	}
	else if(wantsSecureTextField && !self.secureTextField)
	{
		self.secureTextField = [[UITextField alloc] initWithFrame:CGRectZero];
		self.secureTextField.backgroundColor = [UIColor whiteColor];
		self.secureTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
		self.secureTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
		self.secureTextField.returnKeyType = UIReturnKeyNext;
		self.secureTextField.borderStyle = UITextBorderStyleLine;
		self.secureTextField.placeholder = @"Password";
		self.secureTextField.secureTextEntry = YES;
		[self addSubview:self.secureTextField];
	}
}

- (CGRect)layoutTextFieldsWithinRect:(CGRect)boundingRect
{
	const CGFloat kAHTextFieldBottomMargin = 8;
	const CGFloat kAHTextFieldLeading = -1;

	[self ensureTextFieldsForCurrentAlertStyle];

	NSMutableArray *textFields = [NSMutableArray arrayWithCapacity:2];

	if(self.plainTextField)
		[textFields addObject:self.plainTextField];
	if(self.secureTextField)
		[textFields addObject:self.secureTextField];

	for(UITextField *textField in textFields)
	{
		CGRect fieldFrame = CGRectMake(boundingRect.origin.x, boundingRect.origin.y,
									   boundingRect.size.width, kAHAlertViewDefaultTextFieldHeight);
		textField.frame = fieldFrame;

		CGFloat leading = (textField != [textFields lastObject]) ? kAHTextFieldLeading : 0;
		boundingRect.origin.y = CGRectGetMaxY(fieldFrame) + leading;
	}

	if([textFields count] > 0)
		boundingRect.origin.y += kAHTextFieldBottomMargin;

	return boundingRect;
}

- (CGRect)layoutButtonsWithinRect:(CGRect)boundingRect
{
	const CGFloat kAHButtonBottomMargin = 4;
	const CGFloat kAHButtonHorizontalSpacing = 4;

	[self applyAppearanceAttributesToButtons];

	NSArray *allButtons = [self allButtonsInHIGDisplayOrder];

	if([self shouldUseSingleRowButtonLayout])
	{
		CGFloat buttonWidth = ((boundingRect.size.width + kAHButtonHorizontalSpacing) / [allButtons count]);
		buttonWidth -= kAHButtonHorizontalSpacing;

		for(UIButton *button in allButtons)
		{
			CGRect buttonFrame = CGRectMake(boundingRect.origin.x, boundingRect.origin.y,
											buttonWidth, kAHAlertViewDefaultButtonHeight);
			button.frame = buttonFrame;

			boundingRect.origin.x = CGRectGetMaxX(buttonFrame) + kAHButtonHorizontalSpacing;
		}
		
		boundingRect.origin.y = CGRectGetMaxY([[allButtons lastObject] frame]) + kAHButtonBottomMargin;
	}
	else
	{
		for(UIButton *button in allButtons)
		{
			CGRect buttonFrame = CGRectMake(boundingRect.origin.x, boundingRect.origin.y,
											boundingRect.size.width, kAHAlertViewDefaultButtonHeight);
			button.frame = buttonFrame;

			CGFloat margin = (button != [allButtons lastObject]) ? kAHButtonBottomMargin : 0;
			boundingRect.origin.y = CGRectGetMaxY(buttonFrame) + margin;
		}
	}
	
	return boundingRect;
}

- (void)layoutBackgroundImageView
{
	if(!self.backgroundImageView)
	{
		self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
		self.backgroundImageView.autoresizingMask = kAHViewAutoresizingFlexibleSizeAndMargins;
		self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
		[self insertSubview:self.backgroundImageView atIndex:0];
	}

	self.backgroundImageView.image = self.backgroundImage;
}

- (UILabel *)addLabelAsSubview
{
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.backgroundColor = [UIColor clearColor];
	label.textAlignment = UITextAlignmentCenter;
	label.numberOfLines = 0;
	[self addSubview:label];
	
	return label;
}

- (void)applyTextAttributes:(NSDictionary *)attributes toLabel:(UILabel *)label {
	label.font = [attributes objectForKey:UITextAttributeFont];
	label.textColor = [attributes objectForKey:UITextAttributeTextColor];
	label.shadowColor = [attributes objectForKey:UITextAttributeTextShadowColor];
	label.shadowOffset = [[attributes objectForKey:UITextAttributeTextShadowOffset] CGSizeValue];
}

- (void)applyTextAttributes:(NSDictionary *)attributes toButton:(UIButton *)button {
	button.titleLabel.font = [attributes objectForKey:UITextAttributeFont];
	[button setTitleColor:[attributes objectForKey:UITextAttributeTextColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:[attributes objectForKey:UITextAttributeTextShadowColor] forState:UIControlStateNormal];
	button.titleLabel.shadowOffset = [[attributes objectForKey:UITextAttributeTextShadowOffset] CGSizeValue];
}

- (void)applyBackgroundImages:(NSDictionary *)imagesForStates toButton:(UIButton *)button {
	[imagesForStates enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[button setBackgroundImage:obj forState:[key integerValue]];
	}];
}

- (void)applyAppearanceAttributesToButtons
{
	if(self.cancelButton)
	{
		[self applyBackgroundImages:self.cancelButtonBackgroundImagesForControlStates
						   toButton:self.cancelButton];
		[self applyTextAttributes:self.buttonTitleTextAttributes toButton:self.cancelButton];
	}

	if(self.destructiveButton)
	{
		[self applyBackgroundImages:self.destructiveButtonBackgroundImagesForControlStates
						   toButton:self.destructiveButton];
		[self applyTextAttributes:self.buttonTitleTextAttributes toButton:self.destructiveButton];
	}

	for(UIButton *otherButton in self.otherButtons)
	{
		[self applyBackgroundImages:self.buttonBackgroundImagesForControlStates
						   toButton:otherButton];
		[self applyTextAttributes:self.buttonTitleTextAttributes toButton:otherButton];
	}
}

- (NSArray *)allButtonsInHIGDisplayOrder
{
	NSMutableArray *allButtons = [NSMutableArray array];
	if(self.destructiveButton)
		[allButtons addObject:self.destructiveButton];
	if([self.otherButtons count] > 0)
		[allButtons addObjectsFromArray:self.otherButtons];
	if(self.cancelButton)
		[allButtons addObject:self.cancelButton];

	if([self shouldUseSingleRowButtonLayout]) {
		allButtons = [NSArray arrayWithObjects:self.cancelButton, [allButtons objectAtIndex:0], nil];
	}

	return allButtons;
}

- (BOOL)shouldUseSingleRowButtonLayout
{
	UIButton *cancelButtonOrNil = self.cancelButton;
	UIButton *onlyOtherButtonOrNil = self.destructiveButton;
	if(!onlyOtherButtonOrNil && [self.otherButtons count] == 1)
		onlyOtherButtonOrNil = [self.otherButtons objectAtIndex:0];

	if(!cancelButtonOrNil || !onlyOtherButtonOrNil)
		return NO;

	return YES;
}

#pragma mark - Keyboard helpers

- (void)keyboardFrameChanged:(NSNotification *)notification
{
	keyboardIsVisible = ![notification.name isEqualToString:UIKeyboardWillHideNotification];

	CGRect keyboardFrame = [[[notification userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect transformedFrame = CGRectApplyAffineTransform(keyboardFrame, [self transformForCurrentOrientation]);
	keyboardHeight = transformedFrame.size.height;

	if(!keyboardIsVisible)
		keyboardHeight = 0.0;

	if(!isDismissing)
		[self setNeedsLayout];
}

#pragma mark - Orientation helpers

- (CGAffineTransform)transformForCurrentOrientation
{
	CGAffineTransform transform = CGAffineTransformIdentity;
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if(orientation == UIInterfaceOrientationPortraitUpsideDown)
		transform = CGAffineTransformMakeRotation(M_PI);
	else if(orientation == UIInterfaceOrientationLandscapeLeft)
		transform = CGAffineTransformMakeRotation(-M_PI_2);
	else if(orientation == UIInterfaceOrientationLandscapeRight)
		transform = CGAffineTransformMakeRotation(M_PI_2);
	
	return transform;
}

- (void)rotateToMatchInterfaceOrientation
{
	CGAffineTransform baseTransform = [self transformForCurrentOrientation];

	AHAnimationBlock layoutBlock = ^{
		self.transform = baseTransform;

		CGPoint keyboardOffset = CGPointMake(0, -keyboardHeight);
		keyboardOffset = CGPointApplyAffineTransform(keyboardOffset, self.transform);
		CGRect superviewBounds = self.superview.bounds;
		superviewBounds.size.width += keyboardOffset.x;
		superviewBounds.size.height += keyboardOffset.y;

		CGPoint newCenter = CGPointMake(superviewBounds.size.width * 0.5, superviewBounds.size.height * 0.5);
		self.center = newCenter;
	};

	CGFloat delta = CGAffineTransformGetAbsoluteRotationAngleDifference(self.transform, baseTransform);
	const CGFloat HALF_PI = 1.581; // Don't use M_PI_2 here; precision errors will cause incorrect results below.
	BOOL isDoubleRotation = (delta > HALF_PI);

	if(hasLayedOut)
	{
		CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];

		// Egregious hax. iPad lies about its rotation duration.
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			duration = 0.4;

		if(isDoubleRotation)
			duration *= 2;

		[UIView animateWithDuration:duration animations:layoutBlock];
	}
	else
		layoutBlock();

	hasLayedOut = YES;
}

- (void)deviceOrientationChanged:(NSNotification *)notification
{
	UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];

	if(previousOrientation != currentOrientation)
	{
		previousOrientation = currentOrientation;
		[self setNeedsLayout];
	}
}

#pragma mark - Drawing utilities for implementing system control styles

- (UIImage *)backgroundGradientImageWithSize:(CGSize)size
{
	CGPoint center = CGPointMake(size.width * 0.5, size.height * 0.5);
	CGFloat innerRadius = 0;
    CGFloat outerRadius = sqrtf(size.width * size.width + size.height * size.height) * 0.5;

	BOOL opaque = NO;
    UIGraphicsBeginImageContextWithOptions(size, opaque, [[UIScreen mainScreen] scale]);
	CGContextRef context = UIGraphicsGetCurrentContext();

    const size_t locationCount = 2;
    CGFloat locations[locationCount] = { 0.0, 1.0 };
    CGFloat components[locationCount * 4] = {
		0.0, 0.0, 0.0, 0.1, // More transparent black
		0.0, 0.0, 0.0, 0.7  // More opaque black
	};
	
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, locations, locationCount);
	
    CGContextDrawRadialGradient(context, gradient, center, innerRadius, center, outerRadius, 0);
	
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGColorSpaceRelease(colorspace);
    CGGradientRelease(gradient);
	
    return image;
}

#pragma mark - Class drawing utilities for implementing system control styles

+ (UIImage *)alertBackgroundImage
{
	CGRect rect = CGRectMake(0, 0, kAHAlertViewDefaultWidth, kAHAlertViewMinimumHeight);
	const CGFloat lineWidth = 2;
	const CGFloat cornerRadius = 8;

	CGFloat shineWidth = rect.size.width * 1.33;
	CGFloat shineHeight = rect.size.width * 0.2;
	CGFloat shineOriginX = rect.size.width * 0.5 - shineWidth * 0.5;
	CGFloat shineOriginY = -shineHeight * 0.45;
	CGRect shineRect = CGRectMake(shineOriginX, shineOriginY, shineWidth, shineHeight);

	UIColor *fillColor = [UIColor colorWithRed:1/255.0 green:21/255.0 blue:54/255.0 alpha:0.9];
	UIColor *strokeColor = [UIColor colorWithWhite:1.0 alpha:0.7];
	
	BOOL opaque = NO;
    UIGraphicsBeginImageContextWithOptions(rect.size, opaque, [[UIScreen mainScreen] scale]);

	CGRect fillRect = CGRectInset(rect, lineWidth, lineWidth);
	UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius];
	[fillColor setFill];
	[fillPath fill];
	
	CGRect strokeRect = CGRectInset(rect, lineWidth * 0.5, lineWidth * 0.5);
	UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:cornerRadius];
	strokePath.lineWidth = lineWidth;
	[strokeColor setStroke];
	[strokePath stroke];
	
	UIBezierPath *shinePath = [UIBezierPath bezierPathWithOvalInRect:shineRect];
	[fillPath addClip];
	[shinePath addClip];
	
    const size_t locationCount = 2;
    CGFloat locations[locationCount] = { 0.0, 1.0 };
    CGFloat components[locationCount * 4] = {
		1, 1, 1, 0.75,  // Translucent white
		1, 1, 1, 0.05   // More translucent white
	};
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, locationCount);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGPoint startPoint = CGPointMake(CGRectGetMidX(shineRect), CGRectGetMinY(shineRect));
	CGPoint endPoint = CGPointMake(CGRectGetMidX(shineRect), CGRectGetMaxY(shineRect));
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	CGFloat capHeight = CGRectGetMaxY(shineRect);
	CGFloat capWidth = rect.size.width * 0.5;
	return [image resizableImageWithCapInsets:UIEdgeInsetsMake(capHeight, capWidth, capHeight, capWidth)];
}

+ (UIImage *)normalButtonBackgroundImage
{
	const size_t locationCount = 4;
	CGFloat opacity = 1.0;
    CGFloat locations[locationCount] = { 0.0, 0.5, 0.5 + 0.0001, 1.0 };
    CGFloat components[locationCount * 4] = {
		179/255.0, 185/255.0, 199/255.0, opacity,
		121/255.0, 132/255.0, 156/255.0, opacity,
		87/255.0, 100/255.0, 130/255.0, opacity, 
		108/255.0, 120/255.0, 146/255.0, opacity,
	};
	return [self glassButtonBackgroundImageWithGradientLocations:locations
													  components:components
												   locationCount:locationCount];
}

+ (UIImage *)cancelButtonBackgroundImage
{
	const size_t locationCount = 4;
	CGFloat opacity = 1.0;
    CGFloat locations[locationCount] = { 0.0, 0.5, 0.5 + 0.0001, 1.0 };
    CGFloat components[locationCount * 4] = {
		164/255.0, 169/255.0, 184/255.0, opacity,
		77/255.0, 87/255.0, 115/255.0, opacity,
		51/255.0, 63/255.0, 95/255.0, opacity,
		78/255.0, 88/255.0, 116/255.0, opacity,
	};
	return [self glassButtonBackgroundImageWithGradientLocations:locations
													  components:components
												   locationCount:locationCount];
}

+ (UIImage *)glassButtonBackgroundImageWithGradientLocations:(CGFloat *)locations
												  components:(CGFloat *)components
											   locationCount:(NSInteger)locationCount
{
	const CGFloat lineWidth = 1;
	const CGFloat cornerRadius = 4;
	UIColor *strokeColor = [UIColor colorWithRed:1/255.0 green:11/255.0 blue:39/255.0 alpha:1.0];
	
	CGRect rect = CGRectMake(0, 0, cornerRadius * 2 + 1, kAHAlertViewDefaultButtonHeight);

	BOOL opaque = NO;
    UIGraphicsBeginImageContextWithOptions(rect.size, opaque, [[UIScreen mainScreen] scale]);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, locationCount);
	
	CGRect strokeRect = CGRectInset(rect, lineWidth * 0.5, lineWidth * 0.5);
	UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:cornerRadius];
	strokePath.lineWidth = lineWidth;
	[strokeColor setStroke];
	[strokePath stroke];
	
	CGRect fillRect = CGRectInset(rect, lineWidth, lineWidth);
	UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius];
	[fillPath addClip];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	CGFloat capHeight = floorf(rect.size.height * 0.5);
	return [image resizableImageWithCapInsets:UIEdgeInsetsMake(capHeight, cornerRadius, capHeight, cornerRadius)];
}

@end
