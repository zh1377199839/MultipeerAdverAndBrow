//
//  ViewController.m
//  MultipeerAdverAndBrow
//
//  Created by zhaohong on 16/5/26.
//  Copyright © 2016年 zhaohong. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "Constant.h"
#import "sys/utsname.h"
@interface ViewController ()<MCSessionDelegate,MCNearbyServiceBrowserDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,MCNearbyServiceAdvertiserDelegate>
{
    NSString *deviceStr;//当前的设备
    MCPeerID *myPeerID;//我的peerID
    
    
    
    NSMutableArray *nearBluesArray;//搜索到的附近的蓝牙设备
    NSMutableArray *meConnectBluesArray;//我连接的蓝牙设备
    NSMutableArray *connectMeBluesArray;//连接了我的蓝牙设备
}


@property (strong,nonatomic) MCSession *browerSession;//我连接的会话
@property (strong,nonatomic) MCSession *AdverSession;//连接我的会话


@property (nonatomic,strong)MCNearbyServiceAdvertiser *nearAdverserAssistant;//向附近发送广播的控制器
@property (nonatomic,strong)MCNearbyServiceBrowser *nearBrowserController;//搜索附近的广播

@property (strong,nonatomic) UIImagePickerController *imagePickerController;//照片选择控制器


@property (weak, nonatomic) IBOutlet UITextField *sendText;//要发送文字
@property (weak, nonatomic) IBOutlet UILabel *gotText;//获取到的文字
@property (weak, nonatomic) IBOutlet UIImageView *sendImgV;//要发送的图片
@property (weak, nonatomic) IBOutlet UIImageView *gotImgV;//接收到的图片






@property (weak, nonatomic) IBOutlet UITextField *toText;//发送给谁
@property (weak, nonatomic) IBOutlet UILabel *fromLab;//消息从哪里获取得到


@property (weak, nonatomic) IBOutlet UILabel *nearBluesLab;//附近搜索到同服务的所有蓝牙
@property (weak, nonatomic) IBOutlet UILabel *meConnectBluesLab;//我连接了的蓝牙设备
@property (weak, nonatomic) IBOutlet UILabel *connectMeBluesLab;//连接了我的蓝牙设备

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    nearBluesArray = [NSMutableArray array];
    meConnectBluesArray = [NSMutableArray array];
    connectMeBluesArray = [NSMutableArray array];
    
    //用不同的设备类型来自动标记不同的peerID
    deviceStr = [self deviceVersion];
    self.title = [NSString stringWithFormat:@"%@",deviceStr];
    
    
    //创建节点
    myPeerID=[[MCPeerID alloc]initWithDisplayName:deviceStr];
    //创建连接的会话,此会话用来存储我连接到的别人广播的蓝牙会话
    _browerSession=[[MCSession alloc]initWithPeer:myPeerID];
    _browerSession.delegate=self;
    
    
    
    
    //广播的会话，用来保存连接了我的广播的所有设备的会话
    _AdverSession=[[MCSession alloc]initWithPeer:myPeerID];
    _AdverSession.delegate=self;
    _nearAdverserAssistant = [[MCNearbyServiceAdvertiser alloc]initWithPeer:myPeerID discoveryInfo:nil serviceType:@"cmj-photo"];
    _nearAdverserAssistant.delegate = self;
}




#pragma mark ------------------------Delegate-------------------
#pragma mark ------MCSession代理方法
#pragma mark session会话状态改变时
// Remote peer changed state.
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    //此代理没有在主线程上，为了提示框showToastMessage能显示，所以切换为主线程
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        switch (state) {
            case MCSessionStateConnected:
                [Constant showToastMessage:@"连接成功"];
                break;
            case MCSessionStateConnecting:
                [Constant showToastMessage:@"正在连接..."];
                break;
            default:
                [Constant showToastMessage:@"连接失败."];
                break;
        }
        
        //连接我的会话
        if (session == _AdverSession) {
            [connectMeBluesArray removeAllObjects];
            [connectMeBluesArray addObjectsFromArray:_AdverSession.connectedPeers];
        }
        
        
        //我连接的会话
        if (session == _browerSession) {
            [meConnectBluesArray removeAllObjects];
            [meConnectBluesArray addObjectsFromArray:_browerSession.connectedPeers];
        }
        
        
        //刷新界面中的设备连接情况UI
        [self refreshShowBlues];
        
    });

}

#pragma mark session接收到数据时
// Received data from remote peer.
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [Constant showToastMessage:@"接收完数据"];
        
        NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:nil];
        NSString *type = dic[@"type"];//消息类型,0 文字 1图片
        NSString *resultStr = dic[@"source"];//消息来源
        NSString *to = dic[@"to"];//此消息是发送给谁
        NSString *from = dic[@"from"];//此消息从哪发送过来
        
        
        //判断信息是否是发送给自己，如果是，则收下，如果不是则发送给所有连着着的人，不发给来源者,如果来源信息中有自己则不再进行处理
        NSRange range = [from rangeOfString:deviceStr];//判断来源字符串是否包含自己
        if (range.location !=NSNotFound) {
            return ;
        }
        
        
        //来源信息展示
        self.fromLab.text = from;
        
        //如果此消息是发送给自己，则进行展示
        if ([deviceStr isEqualToString:to]) {
            if ([type isEqualToString:@"0"]) {
                
                self.gotText.text = resultStr;
            }else if ([type isEqualToString:@"1"]){
                
                                UIImage *image= [self Base64StrToUIImage:resultStr];
                                [self.gotImgV setImage:image];
            }
            
            
        }
        //如果是发送给所有人，则在展示数据的同时将数据发送给所有自己连接或者被连接的蓝牙设备
        else if([@"" isEqualToString:to])
        {
            if ([type isEqualToString:@"0"]) {
                
                self.gotText.text = resultStr;
            }else if ([type isEqualToString:@"1"]){
                
                                UIImage *image= [self Base64StrToUIImage:resultStr];
                                [self.gotImgV setImage:image];
            }
            
            
            
            
            NSString *fromStr = [NSString stringWithFormat:@"%@,%@",from,deviceStr];
            [dic setObject:fromStr forKey:@"from"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:nil];
            
            
            [self.browerSession sendData: jsonData toPeers:[self.browerSession connectedPeers] withMode:MCSessionSendDataUnreliable error:nil];
            
        }
        
        
        //如果不是发送费自己，则只管发送给别人
        else
        {
            
            
            NSString *fromStr = [NSString stringWithFormat:@"%@,%@",from,deviceStr];
            [dic setObject:fromStr forKey:@"from"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:nil];
            
            
            [self.browerSession sendData: jsonData toPeers:[self.browerSession connectedPeers] withMode:MCSessionSendDataUnreliable error:nil];
        }
        

        
        
    });
 
}

// Received a byte stream from remote peer.
- (void)    session:(MCSession *)session
   didReceiveStream:(NSInputStream *)stream
           withName:(NSString *)streamName
           fromPeer:(MCPeerID *)peerID
{
    
}

// Start receiving a resource from remote peer.
- (void)                    session:(MCSession *)session
  didStartReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                       withProgress:(NSProgress *)progress
{
    
}

// Finished receiving a resource from remote peer and saved the content
// in a temporary location - the app is responsible for moving the file
// to a permanent location within its sandbox.
- (void)                    session:(MCSession *)session
 didFinishReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                              atURL:(NSURL *)localURL
                          withError:(nullable NSError *)error
{
    
}


// Made first contact with peer and have identity information about the
// remote peer (certificate may be nil).
- (void)        session:(MCSession *)session
  didReceiveCertificate:(nullable NSArray *)certificate
               fromPeer:(MCPeerID *)peerID
     certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    //apple 的bug，当使用nearAdverserAssistant时必须加这个回调
    certificateHandler(YES);
}

#pragma mark- MCNearbyServiceAdvertiserDelegate

// Incoming invitation request.  Call the invitationHandler block with YES
// and a valid session to connect the inviting peer to the session.
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    [Constant showToastMessage:@"接受邀请"];
    
    if ([_AdverSession.connectedPeers containsObject:peerID]) {
        [Constant showToastMessage:@"已经连接上，不需要再次连接"];
        return;
    }
    invitationHandler(YES,_AdverSession);
}

// Advertising did not start due to an error.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    [Constant showToastMessage:@"广播失败"];
}

#pragma mark - MCNearbyServiceBrowserDelegate

// Found a nearby advertising peer.
- (void)        browser:(MCNearbyServiceBrowser *)browser
              foundPeer:(MCPeerID *)peerID
      withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    [Constant showToastMessage:[NSString stringWithFormat:@"发现-%@-",peerID.displayName]];
    
    //记录搜索到的附近所有广播
    if (![nearBluesArray containsObject:peerID]) {
        [nearBluesArray addObject:peerID];
    }
    
    
    //连接搜索到的所有广播
    if (![_browerSession.connectedPeers containsObject:peerID]) {
        [_nearBrowserController invitePeer:peerID toSession:_browerSession withContext:nil timeout:30];
    }
    
    
    [self refreshShowBlues];
    //[_nearBrowserController  stopBrowsingForPeers];
}

// A nearby peer has stopped advertising.
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    
    //删除丢失的peerID
    if ([nearBluesArray containsObject:peerID]) {
        [nearBluesArray removeObject:peerID];
    }
    
    [Constant showToastMessage:[NSString stringWithFormat:@"断开和-%@-连接",peerID.displayName]];
    
    [self refreshShowBlues];
}


// Browsing did not start due to an error.
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    [Constant showToastMessage:@"搜索附近广播失败"];
}








#pragma mark --------------------------Actions-------------------
#pragma mark 开始广播并同时搜索附近的广播
- (IBAction)browserAndAdver:(UIBarButtonItem *)sender {
    
    
    //搜索附近的广播
    _nearBrowserController = [[MCNearbyServiceBrowser alloc]initWithPeer:myPeerID serviceType:@"cmj-photo"];
    _nearBrowserController.delegate = self;
    //开始搜索
    [_nearBrowserController  startBrowsingForPeers];
    
    
    
    //-------------------------开始广播，让附近的蓝牙来搜索---------------
    [self.nearAdverserAssistant startAdvertisingPeer];
}
#pragma mark 选择照片
- (IBAction)selectPhoto:(UIBarButtonItem *)sender {
    _imagePickerController=[[UIImagePickerController alloc]init];
    _imagePickerController.delegate=self;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}




#pragma mark 发送文字
- (IBAction)sendTextAction:(id)sender {
    //发送数据给所有已连接设备
    NSError *error=nil;
    
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    [dataDic setObject:@"0" forKey:@"type"];
    [dataDic setObject:[self.toText.text uppercaseString] forKey:@"to"];
    [dataDic setObject:deviceStr forKey:@"from"];
    [dataDic setObject:self.sendText.text forKey:@"source"];
    
    //    NSData *data = [self.sendText.text dataUsingEncoding:NSUTF8StringEncoding];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    [self.browerSession sendData: jsonData toPeers:[self.browerSession connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
    [Constant showToastMessage:@"开始发送数据"];
    if (error) {
        
        [Constant showToastMessage:@"发送数据过程中发生错误，错误信息："];
    }
    
}

#pragma mark 发送图片
- (IBAction)sendImageAction:(id)sender {
    
    if (!self.sendImgV.image) {
        [Constant showToastMessage:@"还没有选择要发送的图片"];
        return;
    }
    //发送数据给所有已连接设备
    NSError *error=nil;
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    [dataDic setObject:@"1" forKey:@"type"];
    [dataDic setObject:[self.toText.text uppercaseString] forKey:@"to"];
    [dataDic setObject:deviceStr forKey:@"from"];
    [dataDic setObject:[self UIImageToBase64Str:self.sendImgV.image] forKey:@"source"];
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    [self.browerSession sendData:jsonData toPeers:[self.browerSession connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
    [Constant showToastMessage:@"开始发送数据"];
    if (error) {
        
        [Constant showToastMessage:@"发送数据过程中发生错误，错误信息："];
    }
}







#pragma mark -------------------------------无关紧要-------------------------
#pragma mark 刷新下面展示的蓝牙连接情况
- (void)refreshShowBlues
{
    self.nearBluesLab.text = [nearBluesArray componentsJoinedByString:@","];
    
    self.meConnectBluesLab.text = [meConnectBluesArray componentsJoinedByString:@","];
    
    self.connectMeBluesLab.text = [connectMeBluesArray componentsJoinedByString:@","];
}
#pragma mark 返回设备类型
- (NSString*)deviceVersion
{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //iPhone
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"4S";
    if ([deviceString isEqualToString:@"iPhone5,1"])    return @"5";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"5";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"5C";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"5C";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"5S";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"5S";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"6Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"6sPlus";
    
    //iPod
    
    if ([deviceString isEqualToString:@"iPod1,1"]) return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"]) return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"]) return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"]) return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPod5,1"]) return @"iPod Touch 5G";
    
    
    //iPad
    if ([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([deviceString isEqualToString:@"iPad2,4"])      return @"iPad 2 (32nm)";
    if ([deviceString isEqualToString:@"iPad2,5"])      return @"iPad mini (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,6"])      return @"iPad mini (GSM)";
    if ([deviceString isEqualToString:@"iPad2,7"])      return @"iPad mini (CDMA)";
    
    if ([deviceString isEqualToString:@"iPad3,1"])      return @"iPad 3(WiFi)";
    if ([deviceString isEqualToString:@"iPad3,2"])      return @"iPad 3(CDMA)";
    if ([deviceString isEqualToString:@"iPad3,3"])      return @"iPad 3(4G)";
    if ([deviceString isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([deviceString isEqualToString:@"iPad3,5"])      return @"iPad 4 (4G)";
    if ([deviceString isEqualToString:@"iPad3,6"])      return @"iPad 4 (CDMA)";
    
    if ([deviceString isEqualToString:@"iPad4,1"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,2"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad5,3"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    
    if ([deviceString isEqualToString:@"iPad4,4"]||[deviceString isEqualToString:@"iPad4,5"]||[deviceString isEqualToString:@"iPad4,6"])
        return @"iPad mini 2";
    if ([deviceString isEqualToString:@"iPad4,7"]||[deviceString isEqualToString:@"iPad4,8"]||[deviceString isEqualToString:@"iPad4,9"])  return @"iPad mini 3";
    return deviceString;
}

#pragma mark 图片压缩到指定大小 140*140
-(UIImage *) imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth
{

    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = defineWidth;
    UIGraphicsBeginImageContext(CGSizeMake(targetWidth, targetHeight));
    [sourceImage drawInRect:CGRectMake(0,0,targetWidth,  targetHeight)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
#pragma mark 图片转字符串
-(NSString *)UIImageToBase64Str:(UIImage *) image
{
    NSData *data = UIImagePNGRepresentation(image);
    NSString *encodedImageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return encodedImageStr;
}

#pragma mark 字符串转图片
-(UIImage *)Base64StrToUIImage:(NSString *)_encodedImageStr
{
    NSData *_decodedImageData   = [[NSData alloc] initWithBase64Encoding:_encodedImageStr];
    UIImage *_decodedImage      = [UIImage imageWithData:_decodedImageData];
    return _decodedImage;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark UIImagePickerController代理方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIImage *image=[info objectForKey:UIImagePickerControllerOriginalImage];
         self.sendImgV.image =  [self imageCompressForWidth:image targetWidth:140];
        
        
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
        
    });
    
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
