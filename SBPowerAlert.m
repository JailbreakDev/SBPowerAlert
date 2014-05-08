#import <SystemConfiguration/CaptiveNetwork.h>
#import <libactivator/libactivator.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach_host.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <arpa/inet.h>
#import <sys/param.h>
#import <sys/mount.h>
#import <ifaddrs.h>
#import <unistd.h>
#import "MobileGestalt.h"
#import "NSHost.h"

//settings path
#define SETTINGS_PATH @"/var/mobile/Library/Preferences/com.sharedRoutine.sbpoweralert.plist"

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

@interface SBPowerAlert : NSObject <LAListener, UIAlertViewDelegate> {
    
@private
    UIAlertView *av;
    NSDictionary *settingsDict;
}
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
    pageSize /= 4;
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

@implementation SBPowerAlert

//reload settings dictionary
-(void)settingsChanged {
    
    if (settingsDict) {
        settingsDict = nil;
    }
    
    settingsDict = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH] ?: [NSDictionary dictionary];

	showDataIP = [settingsDict[@"kShowDataIP"] boolValue];
	showWifiNetwork = settingsDict[@"kShowWifiNetwork"] ? [settingsDict[@"kShowWifiNetwork"] boolValue] : TRUE;
	showWifiIP = settingsDict[@"kShowWifiIP"] ? [settingsDict[@"kShowWifiIP"] boolValue] : TRUE;
	showRam = settingsDict[@"kShowRAM"] ? [settingsDict[@"kShowRAM"] boolValue] : TRUE;
	showStorage = settingsDict[@"kShowStorage"] ? [settingsDict[@"kShowStorage"] boolValue] : TRUE;
	showVersion = [settingsDict[@"kShowiOSVer"] boolValue];

	showReboot = settingsDict[@"kShowRebootButton"] ? [settingsDict[@"kShowRebootButton"] boolValue] : TRUE;
	showPowerOff = settingsDict[@"kShowPowerOffButton"] ? [settingsDict[@"kShowPowerOffButton"] boolValue] : TRUE;
	showRespring = settingsDict[@"kShowRespringButton"] ? [settingsDict[@"kShowRespringButton"] boolValue] : TRUE;
	showSafeMode = settingsDict[@"kShowSafeModeButton"] ? [settingsDict[@"kShowSafeModeButton"] boolValue] : TRUE;
	showLock = [settingsDict[@"kShowLockButton"] boolValue];
}

-(BOOL)dismiss {
    if (av) {
        [av dismissWithClickedButtonIndex:[av cancelButtonIndex] animated:YES];
        [av release];
        av = nil;
        return YES;
    }
    return NO;
}

//do actions depending on which button was clicked
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {

    NSString *btnTitle = [alertView buttonTitleAtIndex:index];

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
        system("touch /var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat");
        system("killall SpringBoard");  
    }
    
    if ([btnTitle isEqualToString:@"Lock"]) {
        [[LAActivator sharedInstance] sendEvent:nil toListenerWithName:@"libactivator.system.sleepbutton"];
    }
    
    [self dismiss];
}


-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [av release];
    av = nil;
}

//shows the alert and stuff
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    
    if (![self dismiss]) {
        
        av = [[UIAlertView alloc] init];
        av.delegate = self;
        
        NSMutableString *info = [[NSMutableString alloc] init];

   		[self settingsChanged];
        
        struct statfs rootFSStats;
        struct statfs fsStats;
        statfs("/", &rootFSStats);
        statfs("/var/", &fsStats);
        float availableSpace_r = (float)(rootFSStats.f_bavail * rootFSStats.f_bsize);
        float availableSpace = (float)(fsStats.f_bavail * fsStats.f_bsize);
        
        CFStringRef wifiAddr = MGCopyAnswer(kMGWifiAddress);
        CFStringRef productVersion = MGCopyAnswer(kMGProductVersion);
        CFStringRef deviceName = MGCopyAnswer(kMGUserAssignedDeviceName);
        
        if (showDataIP) {
            [info appendFormat:@"Data IP: Loading...\n"];
        }
            
        if (showWifiNetwork) {
            [info appendFormat:@"Wi-Fi Network: %@ (%@)\n",currentWifiSSID(), wifiAddr];
        }
            
        if (showWifiIP) {
            [info appendFormat:@"Wi-Fi IP Address: %@\n",getIPAddress()];
        }
            
        if (showRam) {
            [info appendFormat:@"%@ of RAM available\n",[NSByteCountFormatter stringFromByteCount:getAvailableMemory() countStyle:NSByteCountFormatterCountStyleMemory]];
        }
        
        if (showStorage) { 
            [info appendFormat:@"Storage: %.f MB on / - %.f MB on /var\n",availableSpace_r / 1024 / 1024, availableSpace / 1024 / 1024];
        }

        if (showVersion) {
            [info appendFormat:@"%@ is running iOS %@\n",deviceName, productVersion];
        }
        
        av.message = @"SBPowerAlert Information";
        
        if (showReboot) {
            [av addButtonWithTitle:@"Reboot"];
        }
        
        if (showPowerOff) { 
        	[av addButtonWithTitle:@"Power Off"];
        }

        if (showRespring) {
        	[av addButtonWithTitle:@"Respring"];
        }
        
        if (showSafeMode) {
            [av addButtonWithTitle:@"Safe Mode"];
        }
        
        if (showLock) {
            [av addButtonWithTitle:@"Lock"];
        }

        if (!showDataIP && !showWifiNetwork && !showWifiIP && !showRam && !showStorage && !showVersion) { //no info
        	[av addButtonWithTitle:@"Cancel"];
        	[av show];
        	[event setHandled:YES];
        	return;
        }
        
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0,0,255,100)];
        textView.clipsToBounds = YES;
    	[textView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.7]];
    	[textView.layer setBorderWidth:2.0];
    	[textView.layer setCornerRadius:4.0];
    	[textView setText:info];
    	[textView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    	[textView setEditable:FALSE];
    	[textView setTextContainerInset:UIEdgeInsetsMake(5, 5, 5, 5)];
        [textView.layer setBorderWidth:2.0];
        [av setValue:textView forKey:@"accessoryView"];
        [textView release];
        [info release];
        [av addButtonWithTitle:@"Cancel"];
        [av show];
        
        if (showDataIP) {
        	[self performSelector:@selector(updateText:) withObject:textView afterDelay:0];
        }

        [event setHandled:YES];

    }
}

-(void)updateText:(UITextView *)textView {
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
    	NSString *text = [textView text];
		NSString *dataIP = [[NSHost currentHost] addresses][0];
   	 	dispatch_sync(dispatch_get_main_queue(), ^{
            [textView setText:[text stringByReplacingOccurrencesOfString:@"Loading..." withString:dataIP]];
      	});
    });
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

-(void)dealloc {
    [av release];
    [super dealloc];
}

+(void)load {
    	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,settingsChangedCallBack,CFSTR("com.sharedRoutine.settingschanged"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    		[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.sharedroutine.sbpoweralert"];
        [pool release];
}

@end