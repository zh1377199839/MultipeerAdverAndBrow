
/**
 *   Constrant.h
 *   iShow
 *
 *   Created by zhaohong on 16/3/11.
 *   Copyright © 2016年 zhaohong. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
@interface Constant : NSObject


/**
 *  一个对话框提示
 *
 *  @param message 提示语句
 *
 *  @return 返回对话框
 */
//+ (UIAlertView *)showAlertTipMessage:(NSString *)message;
/*!
 @method
 @abstract 通过需要提示的信息，代理，tag和多个button显示一个alert
 @discussion 默认标题为“温馨提示”
 @param message alert需要显示的内容
 @param delegate alert的代理
 @param tag 用于区分弹出的多个alert
 @param otherButtonTitles 多个按钮的名字
 @result void
 */
+ (void)showMessage:(NSString *)message
           delegate:(id)delegate
                tag:(int)tag
       buttonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;


+ (void)showMessageTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
                tag:(int)tag
       buttonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)showToastMessage:(NSString *)message;
+ (void)showToastMessage:(NSString *)message AndTime:(CGFloat )time;
/**
 *  获取当前屏幕显示的控制器
 *
 *  @return controller
 */
+ (UIViewController *)getCurrentVC;

/*
 网络状态
 */
+(int)netWorkingStatus;

@end
