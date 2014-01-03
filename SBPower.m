#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import <mach/mach_host.h>
#import <mach/mach.h>
#import <unistd.h>

@interface UIApplication(SBAdditions)

-(void)_rebootNow;
-(void)_powerDownNow;
-(void)_relaunchSpringBoardNow;

@end


int getAvailableMemory() {

        vm_size_t pageSize;
        host_page_size(mach_host_self(), &pageSize);
        struct vm_statistics vmStats;
        mach_msg_type_number_t infoCount = sizeof(vmStats);
        host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
        int availMem = vmStats.free_count + vmStats.inactive_count;

        return (availMem * pageSize) / 1024 / 1024;
}


@interface SBPower : NSObject<LAListener, UIAlertViewDelegate> {

@private
        UIAlertView *av;
}
@end

@implementation SBPower

- (BOOL)dismiss
{
        // Ensures alert view is dismissed
        // Returns YES if alert was visible previously
        if (av) {
                [av dismissWithClickedButtonIndex:[av cancelButtonIndex] animated:YES];
                [av release];
                av = nil;
                return YES;
        }
        return NO;
}

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
                // [[LAActivator sharedInstance] sendEvent:nil toListenerWithName:@"libactivator.system.safemode"];
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

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
        // Called when we recieve event
        if (![self dismiss]) {
av = [[UIAlertView alloc] init];
         av.delegate = self;
        av.title = [NSString stringWithFormat:@"%d MB available",getAvailableMemory()];
        [av addButtonWithTitle:@"Reboot"];
        [av addButtonWithTitle:@"Power Off"];
        [av addButtonWithTitle:@"Respring"];
        [av addButtonWithTitle:@"Safe Mode"];
        [av addButtonWithTitle:@"Lock"];
        [av addButtonWithTitle:@"Cancel"];
                [av show];
                [event setHandled:YES];
        }
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event
{
        // Called when event is escalated to a higher event
        // (short-hold sleep button becomes long-hold shutdown menu, etc)
        [self dismiss];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event
{
        // Called when some other listener received an event; we should cleanup
        [self dismiss];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event
{
        // Called when the home button is pressed.
        // If (and only if) we are showing UI, we should dismiss it and call setHandled:
        if ([self dismiss])
                [event setHandled:YES];
}

- (void)dealloc
{
        // Since this object lives for the lifetime of SpringBoard, this will never be called
        // It's here for the sake of completeness
        [av release];
        [super dealloc];
}

+ (void)load
{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        // Register our listener
        [[LAActivator sharedInstance] registerListener:[self new] forName:@"com.sharedroutine.sbpower"];
        [pool release];
}

@end 