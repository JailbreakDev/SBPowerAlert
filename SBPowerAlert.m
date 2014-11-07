#import "Headers.h"
#import "SBPowerAlertItem.h"

//information
static BOOL showDataIP;
static BOOL showWifiNetwork;
static BOOL showWifiIP;
static BOOL showRam;
static BOOL showStorage;
static BOOL showVersion;

//buttons
static BOOL showReboot;
static BOOL showPowerOff;
static BOOL showRespring;
static BOOL showSafeMode;
static BOOL showLock;

//SpringBoard methods to reboot, power down and respring
@interface UIApplication(SBAdditions)
-(void)_rebootNow;
-(void)_powerDownNow;
-(void)_relaunchSpringBoardNow;
@end

@class SBPowerAlertItem;
@interface SBPowerAlert : NSObject <LAListener, UIAlertViewDelegate>
@property (nonatomic,strong) SBPowerAlertItem *alertItem;
-(void)settingsChanged;
@end

//callback of the Notification
static void settingsChangedCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userIfo) {
    [(__bridge SBPowerAlert *)observer settingsChanged];
}

//gets available memory for 32 and 64bit
long long getAvailableMemory() {
    vm_size_t pageSize;
    host_page_size(mach_host_self(),&pageSize);
#ifdef __LP64__
    struct vm_statistics64 vmStats;
    mach_msg_type_number_t infoCount = sizeof(vmStats);
    host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vmStats, &infoCount);
    int availMem = vmStats.free_count + vmStats.inactive_count;
    return (availMem * pageSize);
#else
    struct vm_statistics vmStats;
    mach_msg_type_number_t infoCount = sizeof(vmStats);
    host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    int availMem = vmStats.free_count + vmStats.inactive_count;
    return (availMem * pageSize);
#endif
    
}

//gets local IP Address
NSString *getIPAddress() {
    
    NSString *address = @"n/a";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

//gets current wifi name
NSString *currentWifiSSID() {
    NSString *ssid = @"n/a";
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}

//gets available space at path
void availableSpaceForPath(const char *path, CGFloat *outValue) {
    struct statfs fsStats;
    statfs(path, &fsStats);
    *outValue = (CGFloat)(fsStats.f_bavail * fsStats.f_bsize);
}

//returns boolean variable for preferences key, returns default value if key is not found
static Boolean boolForKey(CFStringRef key, Boolean defaultValue) {
    CFPreferencesAppSynchronize(CFSTR("com.sharedRoutine.sbpoweralert"));
    Boolean existsAndValid = FALSE;
    Boolean value = CFPreferencesGetAppBooleanValue(key, CFSTR("com.sharedRoutine.sbpoweralert"), &existsAndValid);
    return existsAndValid ? value : defaultValue;
}

@implementation SBPowerAlert
@synthesize alertItem;

//reload settings dictionary
-(void)settingsChanged {

	showDataIP = boolForKey(CFSTR("kShowDataIP"),FALSE);
	showWifiNetwork = boolForKey(CFSTR("kShowWifiNetwork"),TRUE);
	showWifiIP = boolForKey(CFSTR("kShowWifiIP"),TRUE);
	showRam = boolForKey(CFSTR("kShowRAM"),TRUE);
	showStorage = boolForKey(CFSTR("kShowStorage"),TRUE);
	showVersion = boolForKey(CFSTR("kShowiOSVer"),FALSE);

    showReboot = boolForKey(CFSTR("kShowRebootButton"),TRUE);
    showPowerOff = boolForKey(CFSTR("kShowPowerOffButton"),TRUE);
    showRespring = boolForKey(CFSTR("kShowRespringButton"),TRUE);
    showSafeMode = boolForKey(CFSTR("kShowSafeModeButton"),TRUE);
    showLock = boolForKey(CFSTR("kShowLockButton"),FALSE);
}

-(BOOL)dismiss {
    
    if (self.alertItem) {
        [self.alertItem dismiss];
        self.alertItem = nil;
        return YES;
    }

    return NO;
}

//do actions depending on which button was clicked
-(void)alertView:(UIAlertView *)aAlertView clickedButtonAtIndex:(NSInteger)index {

    NSString *btnTitle = [aAlertView buttonTitleAtIndex:index];

    if ([btnTitle isEqualToString:@"Cancel"]) {
        [self dismiss];
        return;
    }
    
    if ([btnTitle isEqualToString:@"Reboot"]) {
        [[UIApplication sharedApplication] _rebootNow];
    }
    
    if ([btnTitle isEqualToString:@"Power Off"]) {
        [[UIApplication sharedApplication] _powerDownNow]; 
    }
    
    if ([btnTitle isEqualToString:@"Respring"]) {
        [[UIApplication sharedApplication] _relaunchSpringBoardNow];
    }
    
    if ([btnTitle isEqualToString:@"Safe Mode"]) {
        FILE *tmp = fopen("/var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat","w");
        fclose(tmp);
        [[UIApplication sharedApplication] _relaunchSpringBoardNow];
    }
    
    if ([btnTitle isEqualToString:@"Lock"]) {
        [[LAActivator sharedInstance] sendEvent:nil toListenerWithName:@"libactivator.system.sleepbutton"];
    }
    
    [self dismiss];
}

-(void)grabInformationInBackground {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSMutableString *myInfo = [[NSMutableString alloc] init];
        CGFloat availableSpace_r = 0.0f; 
        CGFloat availableSpace = 0.0f;
        availableSpaceForPath("/",&availableSpace_r);
        availableSpaceForPath("/var/",&availableSpace);

        CFStringRef wifiAddr = MGCopyAnswer(kMGWifiAddress);
        CFStringRef productVersion = MGCopyAnswer(kMGProductVersion);
        CFStringRef deviceName = MGCopyAnswer(kMGUserAssignedDeviceName);

        if (showDataIP) {
            [myInfo appendFormat:@"Data IP: %@\n",[[NSHost currentHost] addresses][0]];
        }
                
        if (showWifiNetwork) {
            [myInfo appendFormat:@"Wi-Fi Network: %@ (%@)\n",currentWifiSSID(), wifiAddr];
        }
                
        if (showWifiIP) {
            [myInfo appendFormat:@"Wi-Fi IP Address: %@\n",getIPAddress()];
        }
                
        if (showRam) {
            [myInfo appendFormat:@"%@ of RAM available\n",[NSByteCountFormatter stringFromByteCount:getAvailableMemory() countStyle:NSByteCountFormatterCountStyleMemory]];
        }
            
        if (showStorage) { 
            [myInfo appendFormat:@"Storage: %.f MB on / - %.f MB on /var\n",availableSpace_r / 1024 / 1024, availableSpace / 1024 / 1024];
        }

        if (showVersion) {
            [myInfo appendFormat:@"%@ is running iOS %@\n",deviceName, productVersion];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.alertItem setMessage:myInfo];
            [self.alertItem show];
        });
    });
}

//perform iOS 7 part

-(void)performiOS7Part {

    [self settingsChanged]; //get initial values

    self.alertItem = [[SBPowerAlertItem alloc] initWithTitle:@"SBPowerAlert" message:@"Loading Information..."];

    [self grabInformationInBackground];
        
    if (showReboot) {
        [self.alertItem addButtonWithTitle:@"Reboot"];
    }
        
    if (showPowerOff) { 
        [self.alertItem addButtonWithTitle:@"Power Off"];
    }

    if (showRespring) {
        [self.alertItem addButtonWithTitle:@"Respring"];
    }
        
    if (showSafeMode) {
        [self.alertItem addButtonWithTitle:@"Safe Mode"];
    }
        
    if (showLock) {
        [self.alertItem addButtonWithTitle:@"Lock"];
    }
    [self.alertItem setDelegate:self];
    
}

//perform iOS 8 part

-(void)performiOS8Part {

    [self settingsChanged];

    self.alertItem = [[SBPowerAlertItem alloc] initWithTitle:@"SBPowerAlert" message:@"Loading Information..."];

    [self grabInformationInBackground];

    if (showReboot) {
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Reboot" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                           [[UIApplication sharedApplication] _rebootNow];
                                        }]];
    }
        
    if (showPowerOff) { 
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Power Off" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                           [[UIApplication sharedApplication] _powerDownNow];
                                        }]];
    }

    if (showRespring) {
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                           [[UIApplication sharedApplication] _relaunchSpringBoardNow];
                                        }]];
    }
        
    if (showSafeMode) {
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Safe Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                            FILE *tmp = fopen("/var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat","w");
                                            fclose(tmp);
                                            [[UIApplication sharedApplication] _relaunchSpringBoardNow];
                                        }]];
    }
        
    if (showLock) {
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                           [[LAActivator sharedInstance] sendEvent:nil toListenerWithName:@"libactivator.system.sleepbutton"];
                                        }]];
    }
    
}

//shows the alert and stuff
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    
    if (![self dismiss]) {
        
        if (iOS8) {
            [self performiOS8Part];
        } else if (iOS7) {
            [self performiOS7Part];
        }

        [event setHandled:YES];

    }
}

-(void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
    [self dismiss];
}

-(void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {    
    [self dismiss];
}

-(void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
    if ([self dismiss])
        [event setHandled:YES];
}


+(void)load {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,settingsChangedCallBack,CFSTR("com.sharedRoutine.settingschanged"),NULL,CFNotificationSuspensionBehaviorCoalesce);
    static dispatch_once_t p = 0;

    __strong static SBPowerAlert *_sharedSelf = nil;

    dispatch_once(&p, ^{
        _sharedSelf = [[self alloc] init];
    });
    [[LAActivator sharedInstance] registerListener:_sharedSelf forName:@"com.sharedroutine.sbpoweralert"];
}

@end