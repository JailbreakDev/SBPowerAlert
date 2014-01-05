#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import <mach/mach_host.h>
#import <mach/mach.h>
#import <unistd.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#include <sys/param.h>
#include <sys/mount.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "MobileGestalt.h"
#import "NSHost.h"

//settings path
#define SETTINGS_PATH @"/var/mobile/Library/Preferences/com.sharedRoutine.sbpoweralert.plist"

//SpringBoard methods
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
int getAvailableMemory() {
        
        vm_size_t pageSize;
        host_page_size(mach_host_self(),&pageSize);
#ifdef __LP64__
        struct vm_statistics64 vmStats;
        mach_msg_type_number_t infoCount = sizeof(vmStats);
        host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vmStats, &infoCount);
        int availMem = vmStats.free_count + vmStats.inactive_count;
        pageSize /= 4;
        return ((availMem * pageSize) / 1024 / 1024);
#else
        struct vm_statistics vmStats;
        mach_msg_type_number_t infoCount = sizeof(vmStats);
        host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
        int availMem = vmStats.free_count + vmStats.inactive_count;
        return (int)(availMem * pageSize) / 1024 / 1024;
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
        
        [settingsDict release];
        settingsDict = nil;
    }
    
    settingsDict = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH] ?: [NSDictionary dictionary];
}

- (BOOL)dismiss
{
        if (av) {
                [av dismissWithClickedButtonIndex:[av cancelButtonIndex] animated:YES];
                 [av release];
                 av = nil;
                return YES;
        }
    
    
        return NO;
}

//do actions depending on which button was clicked
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {       

        switch (index) {
                case 0:                        
                 [[UIApplication sharedApplication] _rebootNow];
                        break;

                case 1:
                 [[UIApplication sharedApplication] _powerDownNow]; 
                        break;

                case 2:                        
                 [[UIApplication sharedApplication] _relaunchSpringBoardNow];
                        break;

                case 3:
                      system("touch /var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat");  
                      system("killall SpringBoard");
                       break;

                case 4:                        
                 [[LAActivator sharedInstance] sendEvent:nil toListenerWithName:@"libactivator.system.sleepbutton"];
                        break;

                case 5:
                        //nothing - cancel
                        break;

        }

        [self dismiss];
}


- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
        [av release];
        av = nil;
}

//shows the alert and stuff
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    
        if (![self dismiss]) {
            
            av = [[UIAlertView alloc] init];
            av.delegate = self;
            
            NSMutableString *info = [[NSMutableString alloc] init];
            
            settingsDict = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH] ?: [NSDictionary dictionary];
            
            struct statfs rootFSStats;
            struct statfs fsStats;
            statfs("/", &rootFSStats);
            statfs("/var/", &fsStats);
            float availableSpace_r = (float)(rootFSStats.f_bavail * rootFSStats.f_bsize);
            float availableSpace = (float)(fsStats.f_bavail * fsStats.f_bsize);
            
            CFStringRef wifiAddr = MGCopyAnswer(kMGWifiAddress);
            CFStringRef productVersion = MGCopyAnswer(kMGProductVersion);
            CFStringRef deviceName = MGCopyAnswer(kMGUserAssignedDeviceName);

            
            if ([[settingsDict objectForKey:@"kShowDataIP"] boolValue]) {
                
                [info appendFormat:@"Data IP Address: %@\n",[[NSHost currentHost] addresses][0]];
                
            }
            
            if ([[settingsDict objectForKey:@"kShowWifiNetwork"] boolValue]) {
                
                [info appendFormat:@"Wi-Fi Network: %@ (%@)\n",currentWifiSSID(), wifiAddr];
                
            }
            
            if ([[settingsDict objectForKey:@"kShowWifiIP"] boolValue]) {
                
                [info appendFormat:@"Wi-Fi IP Address: %@\n",getIPAddress()];
                
            }
            
            if ([[settingsDict objectForKey:@"kShowRAM"] boolValue]) {
                
                [info appendFormat:@"%d MB RAM available\n",getAvailableMemory()];
                
            }
            
            if ([[settingsDict objectForKey:@"kShowStorage"] boolValue]) {
                
                [info appendFormat:@"Storage: %.f MB on / - %.f MB on /var\n",availableSpace_r / 1024 / 1024, availableSpace / 1024 / 1024];
                
            }
            
            if ([[settingsDict objectForKey:@"kShowiOSVer"] boolValue]) {
                
                [info appendFormat:@"%@ is running iOS %@\n",deviceName, productVersion];
                
            }
        
            av.message = info;
            [av addButtonWithTitle:@"Reboot"];
            [av addButtonWithTitle:@"Power Off"];
            [av addButtonWithTitle:@"Respring"];
            [av addButtonWithTitle:@"Safe Mode"];
            [av addButtonWithTitle:@"Lock"];
            [av addButtonWithTitle:@"Cancel"];
            [av show];
            [event setHandled:YES];
            
            CFRelease(wifiAddr);
            CFRelease(productVersion);
            CFRelease(deviceName);
            
        }
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event
{
    
        [self dismiss];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event
{
    
        [self dismiss];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event
{
    
        if ([self dismiss])
                [event setHandled:YES];
}

 - (void)dealloc
{
        [av release];
        [settingsDict release];
        [super dealloc];
}

//register stuff
+ (void)load {
    
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        // Register our listener
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,settingsChangedCallBack,CFSTR("com.sharedRoutine.settingschanged"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    
        [[LAActivator sharedInstance] registerListener:[self new] forName:@"com.sharedroutine.sbpoweralert"];
    
        [pool release];
}

@end 