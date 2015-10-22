#import <Preferences/Preferences.h>

@interface SBPowerAlertSettingsListController: PSListController
@property (nonatomic,strong,readonly) UIImage *headerImage;
@end

@implementation SBPowerAlertSettingsListController
@synthesize headerImage = _headerImage;

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"SBPowerAlertSettings" target:self];
	}
	return _specifiers;
}
-(void)supportMe {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SEURCUP448PEA"]];
}

-(UIImage *)headerImage {
	if (!_headerImage) {
		_headerImage = [UIImage imageWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/SBPowerAlertSettings.bundle"] pathForResource:@"header-settings" ofType:@"png"]];
	}
	return _headerImage;
}

-(void)openOHWPackage:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.gx5.onehandwizard"]];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == [tableView numberOfSections]-1) {
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button addTarget:self action:@selector(openOHWPackage:) forControlEvents:UIControlEventTouchUpInside];
		button.frame = CGRectMake(0, 0, self.headerImage.size.width, self.headerImage.size.height);
		[button setImage:self.headerImage forState:UIControlStateNormal];
		return button;
	}
	return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == [tableView numberOfSections]-1) {
		return self.headerImage.size.height;
	}
	return (CGFloat)-1;
}

@end

// vim:ft=objc
