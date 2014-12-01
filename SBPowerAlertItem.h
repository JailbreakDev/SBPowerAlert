#import "Headers.h"

@interface SBAlertItemsController : NSObject
+(id)sharedInstance;
-(void)activateAlertItem:(id)arg1;
-(void)deactivateAlertItem:(id)arg1;
@end

@interface SBAlertItem : NSObject <UIAlertViewDelegate>
+(SBAlertItemsController *)_alertItemsController;
-(UIAlertView *)alertSheet;
-(UIAlertController *)alertController; //iOS 8
-(void)dismiss;
@end

@interface SBPowerAlertItem : SBAlertItem
@property (nonatomic,copy) NSString *alertTitle;
@property (nonatomic,copy) NSString *alertMessage;
@property (nonatomic,copy,readonly) NSMutableArray *actions;
@property (nonatomic,copy,readonly) NSMutableArray *buttons;
@property (nonatomic,assign) id <UIAlertViewDelegate> delegate;
-(instancetype)initWithTitle:(NSString *)title message:(NSString *)message;
-(void)addButtonWithTitle:(NSString *)title;
-(void)addAction:(UIAlertAction *)action;
-(void)setMessage:(NSString *)message;
-(void)show;
@end