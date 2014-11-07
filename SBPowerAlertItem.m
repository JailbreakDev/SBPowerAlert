#import "SBPowerAlertItem.h"

@implementation SBPowerAlertItem
@synthesize alertTitle,alertMessage,actions = _actions;

-(instancetype)initWithTitle:(NSString *)title message:(NSString *)message {
	self = [super init];

	if (self) {
		[self setAlertTitle:title];
		[self setAlertMessage:message];
		if (!self.actions) {
			_actions = [[NSMutableArray alloc] init];
		}
	}

	return self;
}

-(instancetype)initWithActions:(NSArray *)actionArray title:(NSString *)title message:(NSString *)message {
	self = [self initWithTitle:title message:message];

	if (self) {
		_actions = [actionArray mutableCopy];
	}

	return self;
}

-(void)addButtonWithTitle:(NSString *)title {
	[[self alertSheet] addButtonWithTitle:title];
}

-(void)addAction:(UIAlertAction *)action {
	[self.actions addObject:action];
}

-(void)setMessage:(NSString *)message {
	if (iOS8) {
		[[self alertController] setMessage:message];
	} else if (iOS7) {
		[[self alertSheet] setMessage:message];
	}
}

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode {

	if (iOS8) {
		[self alertController].title = self.alertTitle ?: @"";
		[self alertController].message = self.alertMessage ?: @"";
		for (UIAlertAction *action in self.actions) {
			[[self alertController] addAction:action];
		}
		[[self alertController] addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                            [self dismiss];
                                        }]];
		[[self alertController] setModalPresentationStyle:UIModalPresentationFormSheet];
	} else if (iOS7) {
		[self alertSheet].delegate = self.delegate ?: self;
		[self alertSheet].title = self.alertTitle ?: @"";
		[self alertSheet].message = self.alertMessage ?: @"";
	}
}

-(void)show {
	[[objc_getClass("SBAlertItem") _alertItemsController] activateAlertItem:self];
}

@end