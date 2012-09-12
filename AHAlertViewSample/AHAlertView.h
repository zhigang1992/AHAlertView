//
//  AHAlertView.h
//  AHAlertViewSample
//
//  Created by Warren Moore on 9/10/12.
//

#import <UIKit/UIKit.h>

typedef enum {
    AHAlertViewStyleDefault = 0,
    AHAlertViewStyleSecureTextInput,
    AHAlertViewStylePlainTextInput,
    AHAlertViewStyleLoginAndPasswordInput,
} AHAlertViewStyle;

typedef enum {
	AHAlertViewPresentationStyleNone = 0,
	AHAlertViewPresentationStylePop,
	AHAlertViewPresentationStyleFade,
	
	AHAlertViewPresentationStyleDefault = AHAlertViewPresentationStylePop
} AHAlertViewPresentationStyle;

typedef enum {
	AHAlertViewDismissalStyleNone = 0,
	AHAlertViewDismissalStyleZoomDown,
	AHAlertViewDismissalStyleZoomOut,
	AHAlertViewDismissalStyleFade,
	AHAlertViewDismissalStyleTumble,

	AHAlertViewDismissalStyleDefault = AHAlertViewDismissalStyleFade
} AHAlertViewDismissalStyle;

typedef void (^AHAlertViewButtonBlock)();

@interface AHAlertView : UIView

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, readonly, assign, getter = isVisible) BOOL visible;
@property(nonatomic, assign) AHAlertViewStyle alertViewStyle;
@property(nonatomic, assign) AHAlertViewPresentationStyle presentationStyle;
@property(nonatomic, assign) AHAlertViewDismissalStyle dismissalStyle;

- (id)initWithTitle:(NSString *)title message:(NSString *)message;

- (void)addButtonWithTitle:(NSString *)title block:(AHAlertViewButtonBlock)block;
- (void)setDestructiveButtonTitle:(NSString *)title block:(AHAlertViewButtonBlock)block;
- (void)setCancelButtonTitle:(NSString *)title block:(AHAlertViewButtonBlock)block;

- (void)show;
- (void)showWithStyle:(AHAlertViewPresentationStyle)presentationStyle;
- (void)dismiss;
- (void)dismissWithStyle:(AHAlertViewDismissalStyle)dismissalStyle;

- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex;

@property(nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;
@property(nonatomic, assign) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;

@property(nonatomic, copy) NSDictionary *titleTextAttributes UI_APPEARANCE_SELECTOR;
@property(nonatomic, copy) NSDictionary *messageTextAttributes UI_APPEARANCE_SELECTOR;
@property(nonatomic, copy) NSDictionary *buttonTitleTextAttributes UI_APPEARANCE_SELECTOR;

- (void)setButtonBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (UIImage *)buttonBackgroundImageForState:(UIControlState)state UI_APPEARANCE_SELECTOR;

- (void)setCancelButtonBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (UIImage *)cancelButtonBackgroundImageForState:(UIControlState)state UI_APPEARANCE_SELECTOR;

- (void)setDestructiveButtonBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (UIImage *)destructiveButtonBackgroundImageForState:(UIControlState)state UI_APPEARANCE_SELECTOR;

@end
