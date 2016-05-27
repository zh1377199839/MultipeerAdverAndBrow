/**
 *  @file Constrant.m
 *  @brief
 *
 *  Constrant.m
 *  iShow
 *
 *  Created by zhaohong on 16/3/11.
 *  Copyright © 2016年 zhaohong. All rights reserved.
 *
 */

#import "Constant.h"
#import "MBProgressHUD.h"
@implementation Constant
+ (UIAlertView *)showAlertTipMessage:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"好的"
                                              otherButtonTitles:nil];
    [alertView show];
    return  alertView;
}



+ (void)showMessageTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
                tag:(int)tag
       buttonTitles:(NSString *)otherButtonTitles, ...
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:delegate
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
    va_list args;
    va_start(args, otherButtonTitles);
    for (NSString *arg = otherButtonTitles; arg != nil; arg = va_arg(args, NSString*))
    {
        [alertView addButtonWithTitle:arg];
    }
    va_end(args);
    [alertView show];
    alertView.tag = tag;
}
+ (void)showMessage:(NSString *)message
           delegate:(id)delegate
                tag:(int)tag
       buttonTitles:(NSString *)otherButtonTitles, ...
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示"
                                                        message:message
                                                       delegate:delegate
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
    va_list args;
    va_start(args, otherButtonTitles);
    for (NSString *arg = otherButtonTitles; arg != nil; arg = va_arg(args, NSString*))
    {
        [alertView addButtonWithTitle:arg];
    }
    va_end(args);
    [alertView show];
    alertView.tag = tag;
}


+ (void)showToastMessage:(NSString *)message
{
   UIView *view = [UIApplication sharedApplication].keyWindow;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message;    // Move to bottm center.
    hud.label.numberOfLines = 0;//可换行
    hud.offset = CGPointMake(0.f, 1000000.f);

    hud.contentColor = [UIColor whiteColor];
    //
    [hud hideAnimated:YES afterDelay:3.0f];
  
}
+ (void)showToastMessage:(NSString *)message AndTime:(CGFloat )time
{
    UIView *view = [UIApplication sharedApplication].keyWindow;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message;    // Move to bottm center.
    hud.label.numberOfLines = 0;//可换行
    hud.offset = CGPointMake(0.f, 1000000.f);
    
    hud.contentColor = [UIColor whiteColor];
    //
    [hud hideAnimated:YES afterDelay:time];
}





@end
