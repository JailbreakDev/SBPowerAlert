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
#include <objc/runtime.h>
#import "MobileGestalt.h"
#import "NSHost.h"

//CoreFoundation Numbers
#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_7_1_2
#define kCFCoreFoundationVersionNumber_iOS_7_1_2 847.27
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_1_1
#define kCFCoreFoundationVersionNumber_iOS_8_1_1 1141.18
#endif

#define iOS8 kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0 \
&& kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_8_1_1

#define iOS7 kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 \
&& kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1_2

#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)