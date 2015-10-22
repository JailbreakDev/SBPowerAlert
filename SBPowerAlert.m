#import "Headers.h"
#import "SBPowerAlertItem.h"

//information
static BOOL showDataIP;
static BOOL showWifiNetwork;
static BOOL showWifiIP;
static BOOL showRam;
static BOOL showStorage;
static BOOL showVersion;
static BOOL showTraffic;

//buttons
static BOOL showReboot;
static BOOL showPowerOff;
static BOOL showRespring;
static BOOL showSafeMode;
static BOOL showLock;

//SpringBoard methods to reboot, power down and respring
@interface UIApplication(SBAdditions)
-(void)_rebootNow;
-(void)_rebootNow:(BOOL)x;
-(void)_powerDownNow;
-(void)_relaunchSpringBoardNow;
@end

#ifdef __cplusplus
extern "C" {
#endif
void CTRegistrationDataCounterGetAllStatistics(int __unknown0, CGFloat *bytesSent, CGFloat *bytesReceived);
#ifdef __cplusplus
}
#endif

@class SBPowerAlertItem;
@interface SBPowerAlert : NSObject <LAListener, UIAlertViewDelegate>
@property (nonatomic,strong) SBPowerAlertItem *alertItem;
-(void)settingsChanged;
@end

//callback of the Notification
static void settingsChangedCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userIfo) {
    [(__bridge SBPowerAlert *)observer settingsChanged];
}

struct vm_statistics64 stats64() {
    struct vm_statistics64 vmStats;
    mach_msg_type_number_t infoCount = sizeof(vmStats);
    host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vmStats, &infoCount);
    return vmStats;
}

struct vm_statistics stats32() {
    struct vm_statistics vmStats;
    mach_msg_type_number_t infoCount = sizeof(vmStats);
    host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    return vmStats;
}

NSInteger getRam(natural_t ram) {
    vm_size_t pageSize;
    host_page_size(mach_host_self(),&pageSize);
    return (ram * pageSize);
}

//gets available memory for 32 and 64bit
NSInteger getFreeRAM() {
#ifdef __LP64__
    struct vm_statistics64 vmStats = stats64();
    return getRam(vmStats.free_count);
#else
    struct vm_statistics vmStats = stats32();
    return getRam(vmStats.free_count);
#endif
}

NSInteger getActivelyUsedRAM() {
#ifdef __LP64__
    struct vm_statistics64 vmStats = stats64();
    return getRam(vmStats.active_count);
#else
    struct vm_statistics vmStats = stats32();
    return getRam(vmStats.active_count);
#endif
}

NSInteger getInactiveRAM() {
#ifdef __LP64__
    struct vm_statistics64 vmStats = stats64();
    return getRam(vmStats.inactive_count);
#else
    struct vm_statistics vmStats = stats32();
    return getRam(vmStats.inactive_count);
#endif
}

NSInteger getWiredRAM() {
#ifdef __LP64__
    struct vm_statistics64 vmStats = stats64();
    return getRam(vmStats.wire_count);
#else
    struct vm_statistics vmStats = stats32();
    return getRam(vmStats.wire_count);
#endif
    
}

NSArray *getDataCounters() {
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    int WiFiSent = 0;
    int WiFiReceived = 0;
    int WWANSent = 0;
    int WWANReceived = 0;
    
    NSString *name=[[NSString alloc]init];
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WiFiSent+=networkStatisc->ifi_obytes;
                    WiFiReceived+=networkStatisc->ifi_ibytes;
                }
                
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WWANSent+=networkStatisc->ifi_obytes;
                    WWANReceived+=networkStatisc->ifi_ibytes;
                }
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:-(WiFiSent)], [NSNumber numberWithInt:WiFiReceived],[NSNumber numberWithInt:WWANSent],[NSNumber numberWithInt:WWANReceived], nil];
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
    showTraffic = boolForKey(CFSTR("kShowTraffic"),FALSE);

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
        if ([[UIApplication sharedApplication] respondsToSelector:(@selector(_rebootNow))]) {
            [[UIApplication sharedApplication] _rebootNow];
        } else if ([[UIApplication sharedApplication] respondsToSelector:@selector(_rebootNow:)]) {
            [[UIApplication sharedApplication] _rebootNow:FALSE];
        }
    }
    
    if ([btnTitle isEqualToString:@"Power Off"]) {
        [[UIApplication sharedApplication] _powerDownNow]; 
    }
    
    if ([btnTitle isEqualToString:@"Respring"]) {
        [[UIApplication sharedApplication] _relaunchSpringBoardNow];
    }
    
    if ([btnTitle isEqualToString:@"Safe Mode"]) {
        fclose(fopen("/var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat","w"));
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
        CFStringRef productType = MGCopyAnswer(kMGProductType);
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

        if (showTraffic) {
            NSArray *dataCounts = getDataCounters();
            NSNumber *wifiSent = dataCounts[0];
            NSNumber *wifiReceived = dataCounts[1];
            NSString *sentBytes = [NSByteCountFormatter stringFromByteCount:[wifiSent longLongValue] countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *receivedBytes = [NSByteCountFormatter stringFromByteCount:[wifiReceived longLongValue] countStyle:NSByteCountFormatterCountStyleBinary];
            [myInfo appendFormat:@"Wifi Data Sent: %@\nWifi Data Received: %@\n",sentBytes,receivedBytes];
        }
                
        if (showRam) {
            NSString *freeRAM = [NSByteCountFormatter stringFromByteCount:getFreeRAM() countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *activeRAM = [NSByteCountFormatter stringFromByteCount:getActivelyUsedRAM() countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *inactiveRAM = [NSByteCountFormatter stringFromByteCount:getInactiveRAM() countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *wiredRAM = [NSByteCountFormatter stringFromByteCount:getWiredRAM() countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *installedRAM = [NSByteCountFormatter stringFromByteCount:[[NSProcessInfo processInfo] physicalMemory] countStyle:NSByteCountFormatterCountStyleBinary];
            [myInfo appendFormat:@"Free RAM: %@\nActive RAM: %@\nInactive RAM: %@\nWired RAM: %@\nInstalled RAM: %@\n",freeRAM,activeRAM,inactiveRAM,wiredRAM,installedRAM];
        }
            
        if (showStorage) { 
            [myInfo appendFormat:@"Storage: %.f MB on / - %.f MB on /var\n",availableSpace_r / 1024 / 1024, availableSpace / 1024 / 1024];
        }

        if (showVersion) {
            [myInfo appendFormat:@"%@ (%@) is running iOS %@\n",deviceName, productType, productVersion];
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
                                           [self dismiss];
                                           if ([[UIApplication sharedApplication] respondsToSelector:@selector(_rebootNow)]) {
                                                [[UIApplication sharedApplication] _rebootNow];
                                            } else if ([[UIApplication sharedApplication] respondsToSelector:@selector(_rebootNow:)]) {
                                                [[UIApplication sharedApplication] _rebootNow:FALSE];
                                            }
                                        }]];
    }
        
    if (showPowerOff) { 
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Power Off" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                           [self dismiss];
                                           [[UIApplication sharedApplication] _powerDownNow];
                                        }]];
    }

    if (showRespring) {
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                           [self dismiss];
                                           [[UIApplication sharedApplication] _relaunchSpringBoardNow];
                                        }]];
    }
        
    if (showSafeMode) {
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Safe Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                            FILE *tmp = fopen("/var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat","w");
                                            fclose(tmp);
                                            [self dismiss];
                                            [[UIApplication sharedApplication] _relaunchSpringBoardNow];
                                        }]];
    }
        
    if (showLock) {
        [self.alertItem addAction:[objc_getClass("UIAlertAction") actionWithTitle:@"Lock" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                           [self dismiss];
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