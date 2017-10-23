//
//  ViewController.m
//  自动聚焦拍照
//
//  Created by tao on 16/12/30.
//  Copyright © 2016年 tao. All rights reserved.
//

#import "ViewController.h"
#import "ZLCameraViewController.h"
#import "Masonry.h"
#import "AFURLSessionManager.h"
#import "AFHTTPSessionManager.h"
#import "SenNetWorking.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>

#import "AppDelegate.h"

#define JWidth [[UIScreen mainScreen]bounds].size.width
#define JHeight [[UIScreen mainScreen]bounds].size.height

@interface ViewController ()<JSTakePhotosDelegte,UIAlertViewDelegate>


@property (nonatomic,strong)  NSMutableArray * mutImageArray;
@property (nonatomic,strong)  UIImageView * imageIV;
@property (nonatomic,strong)  UITextField * urltextFiled;
@property (nonatomic,strong)  UITextField * timerEndtextFiled;
@property (nonatomic,strong)  UILabel * timerEndLable;
@property (nonatomic,strong)  UILabel * serverAdressLable;
@property (nonatomic,strong)  UITextField * starPhonetextFiled;
@property (nonatomic,strong)  UILabel *starPhoneLable;
@property (nonatomic,strong)  UILabel *upLoadImageLable;
@property (nonatomic,strong)  UIButton *cancleSureBtn;
@property (nonatomic,strong)  UIActivityIndicatorView *activityIndicator;
@property (nonatomic,strong)  NSString *encodedImageStr;
@property (nonatomic,strong)  NSString *sevUrl;
@property (nonatomic,assign)  BOOL IsConet;
@property (nonatomic,assign)  BOOL IsHandStyle;
@property (nonatomic,assign)  BOOL IsStop;

@property (nonatomic,strong)  UIButton *btn1;
@property (nonatomic,strong)  UIButton *btn2;



@property (nonatomic,strong) UIScrollView * backGroundScrollow;
@property (nonatomic,strong) ZLCameraViewController * cameraVC;
@property (nonatomic,strong) UIActivityIndicatorView  * uploadAct;
@property (nonatomic,strong) UILabel  * uploadLabel;
@property (nonatomic,strong) UIButton * uploadButton;
@property (nonatomic,strong) UIView   * uploadView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mutImageArray = [NSMutableArray array];
    
    [self createSubviews];
    
}
-(void)createSubviews{
    self.IsHandStyle = NO;

    _serverAdressLable = [[UILabel alloc]init];
    [_serverAdressLable setFrame:CGRectMake(10, 80, 98, 40)];
    [_serverAdressLable setFont:[UIFont systemFontOfSize:16]];
    [_serverAdressLable setTextColor:[UIColor blackColor]];
    [_serverAdressLable setTextAlignment:NSTextAlignmentCenter];
    [_serverAdressLable setText:@"服务器地址："];
    [self.view addSubview:_serverAdressLable];
    
    
    _urltextFiled=[[UITextField alloc]initWithFrame:CGRectMake(110, 80, self.view.frame.size.width-120, 40)];
    [_urltextFiled setTextColor:[UIColor blackColor]];
    [_urltextFiled setFont:[UIFont systemFontOfSize:16]];
    [_urltextFiled setBorderStyle:UITextBorderStyleRoundedRect];
    [_urltextFiled setPlaceholder:@"请输入服务器路径"];
    [self.view addSubview:_urltextFiled];
    
    
    
    _timerEndLable=[[UILabel alloc]init];
    [_timerEndLable setFrame:CGRectMake(10, 130, 114, 40)];
    [_timerEndLable setFont:[UIFont systemFontOfSize:16]];
    [_timerEndLable setTextColor:[UIColor blackColor]];
    [_timerEndLable setTextAlignment:NSTextAlignmentCenter];
    [_timerEndLable setText:@"停止时间(分)："];
    [self.view addSubview:_timerEndLable];
    
    _timerEndtextFiled=[[UITextField alloc]initWithFrame:CGRectMake(114, 130, self.view.frame.size.width-124, 40)];
    [_timerEndtextFiled setTextColor:[UIColor blackColor]];
    [_timerEndtextFiled setFont:[UIFont systemFontOfSize:16]];
    [_timerEndtextFiled setBorderStyle:UITextBorderStyleRoundedRect];
    [_timerEndtextFiled setPlaceholder:@"请输入停止时间(分)："];
    [_timerEndtextFiled setKeyboardType:UIKeyboardTypePhonePad];
    _timerEndtextFiled.text = @"30";
    [self.view addSubview:_timerEndtextFiled];
    
    
    _starPhoneLable=[[UILabel alloc]init];
    [_starPhoneLable setFrame:CGRectMake(10, 180, 114, 40)];
    [_starPhoneLable setFont:[UIFont systemFontOfSize:16]];
    [_starPhoneLable setTextColor:[UIColor blackColor]];
    [_starPhoneLable setTextAlignment:NSTextAlignmentCenter];
    [_starPhoneLable setText:@"拍照间隔(秒)："];
    [self.view addSubview:_starPhoneLable];
    
    _starPhonetextFiled=[[UITextField alloc]initWithFrame:CGRectMake(114, 180, self.view.frame.size.width-124, 40)];
    [_starPhonetextFiled setTextColor:[UIColor blackColor]];
    [_starPhonetextFiled setFont:[UIFont systemFontOfSize:16]];
    [_starPhonetextFiled setBorderStyle:UITextBorderStyleRoundedRect];
    [_starPhonetextFiled setPlaceholder:@"请输入拍照间隔时间(秒)："];
    [_starPhonetextFiled setKeyboardType:UIKeyboardTypePhonePad];
    _starPhonetextFiled.text=@"30";
    [self.view addSubview:_starPhonetextFiled];
    
    _btn1=[[UIButton alloc]initWithFrame:CGRectMake(15, 240, 60, 30)];
    [_btn1 setTitle:@"手 动" forState:UIControlStateNormal];
    [_btn1 addTarget:self action:@selector(btn1Action) forControlEvents:UIControlEventTouchUpInside];
    [_btn1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btn1.layer setBorderWidth:0.5];
    [_btn1.layer setMasksToBounds:YES];
    [self.view addSubview:_btn1];
    
    _btn2=[[UIButton alloc]initWithFrame:CGRectMake(75, 240, 60, 30)];
    [_btn2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btn2 setBackgroundColor:[UIColor yellowColor]];
    [_btn2.layer setBorderWidth:0.5];
    [_btn2.layer setMasksToBounds:YES];
    [_btn2 setTitle:@"自 动" forState:UIControlStateNormal];
    [_btn2 addTarget:self action:@selector(btn2Action) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btn2];
    
    self.imageIV = [[UIImageView alloc] initWithFrame:CGRectMake((JWidth - 220)/2, 290, 220, 220 * 1.33)];
    self.imageIV.image =  [UIImage imageNamed:@"imageHeader"];
    [self.view addSubview:self.imageIV];
    self.imageIV.hidden  = YES;
    
    self .cancleSureBtn =  [UIButton buttonWithType:UIButtonTypeCustom];
    [self .cancleSureBtn setFrame:CGRectMake(0, self.view.frame.size.height-50, self.view.frame.size.width, 50)];
    [self .cancleSureBtn setTitle:@"开 始" forState:UIControlStateNormal];
    [self .cancleSureBtn.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self .cancleSureBtn addTarget:self action:@selector(startPhone) forControlEvents:UIControlEventTouchUpInside];
    [self .cancleSureBtn setBackgroundColor:[UIColor yellowColor]];
    [self .cancleSureBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:self .cancleSureBtn];
    

    
    
    
    
    UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator = activityIndicator;
    
    activityIndicator.frame = CGRectMake(self.view.frame.size.width/2-20, 65, 40,40);
    activityIndicator.color = [UIColor blackColor];
    [activityIndicator stopAnimating];
    [activityIndicator setHidesWhenStopped:YES];
    
    [self.view addSubview:activityIndicator];
    
    _sevUrl = @"http://47.52.157.117/index.php/Home/Post/index";
    _urltextFiled.text = _sevUrl;
    

    
}
-(void)btn1Action{
    [_btn1 setBackgroundColor:[UIColor yellowColor]];
    [_btn2 setBackgroundColor:[UIColor whiteColor]];
    self.IsHandStyle = YES;
}

-(void)btn2Action{
    [_btn2 setBackgroundColor:[UIColor yellowColor]];
    [_btn1 setBackgroundColor:[UIColor whiteColor]];
    self.IsHandStyle = NO;
}
//进入拍照界面
-(void)startPhone{
    if (self.IsHandStyle) {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"手动拍照" message:@"按音量键拍照一次并自动上传" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [alert show];
    }else{
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"自动拍照" message:[NSString stringWithFormat:@"拍照时间%@秒   每隔%@自动拍照一次",self.timerEndtextFiled.text,self.starPhonetextFiled.text] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [alert show];
    }
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (buttonIndex) {
        case 0:
            [self  presentCameraContinuous];
            break;
            
        default:
            break;
    }
}
-(void)takePhotesSetting{
    

    [_urltextFiled setHidden:YES];
    [_upLoadImageLable  setHidden:NO];
    [_activityIndicator startAnimating];
    [_activityIndicator setHidden:YES];
    [_serverAdressLable setHidden:YES];
    [_timerEndtextFiled setHidden:YES];
    [_btn1 setHidden:YES];
    [_btn2 setHidden:YES];
    [_timerEndLable setHidden:YES];
    
    [_starPhonetextFiled setHidden:YES];
    [_starPhoneLable setHidden:YES];
    _IsConet = NO;
    _IsStop = NO;
    
}
/**
 *  初始化自定义相机（连拍）
 */
#pragma mark - *初始化自定义相机（连拍）
- (void)presentCameraContinuous {
    
    int count = [self.timerEndtextFiled.text intValue] / [self.starPhonetextFiled.text intValue];
    self.cameraVC = [[ZLCameraViewController alloc] init];
    self.cameraVC.delegete = self;
    self.cameraVC.IsHandStyle = self.IsHandStyle;
    self.cameraVC.maxCount = 1;// 拍照最多个数
    self.cameraVC.GraphRecognition = YES;
    self.cameraVC.everyTime = [self.starPhonetextFiled.text intValue];
    self.cameraVC.allTime = [self.timerEndtextFiled.text intValue];
    if (self.IsHandStyle) {
        self.cameraVC.count = 1;
        self.cameraVC.cameraType = ZLCameraSingle;// 单张拍摄
    }else{
        self.cameraVC.count = count;
        self.cameraVC.cameraType = ZLCameraContinuous;
    }
    [self presentViewController:self.cameraVC animated:YES completion:nil];
    
}
-(void)takePhotos:(NSArray *)photosArray{
    
    UIImage * canamer = [photosArray lastObject];
    NSLog(@"拍照结果————：%@",canamer);
    [self.view setNeedsDisplay];
    [self.mutImageArray addObject:canamer];
    int count = [self.timerEndtextFiled.text intValue] / [self.starPhonetextFiled.text intValue];
    //展示拍完的图片
    if (self.mutImageArray.count == count  || self.IsHandStyle) {
        if (!self.backGroundScrollow) {
            self.backGroundScrollow = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 290, JWidth, 220 * 1.33)];
            [self.view addSubview:self.backGroundScrollow];
        }
        self.backGroundScrollow.contentSize = CGSizeMake(10 +  230 * self.mutImageArray.count + 10, 0);
       
        
        for (int k = 0;  k < self.mutImageArray.count; k ++) {
            UIImageView * image1 = [[UIImageView alloc]initWithFrame:CGRectMake(10 +  230 * k, 0, 220, 220 * 1.33)];
            image1.image = self.mutImageArray[k];
            [self.backGroundScrollow addSubview:image1];
        }
    }
    NSData * data = UIImageJPEGRepresentation(canamer, 1.0f);
    _encodedImageStr = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [self uploadImageToServerWithImage:canamer];

}
-(void)uploadImageToServerWithImage:(UIImage *)loadImage{
    
    [self uploadPhotosWithImage:loadImage withUrl:_sevUrl];
}
//上传
-(void)uploadPhotosWithImage:(UIImage *)image  withUrl:(NSString *)url{

    AppDelegate * delegete;
    if (!delegete) {
        delegete = (AppDelegate *)[UIApplication sharedApplication].delegate;
        self.uploadView.frame = delegete.window.bounds;
        [delegete.window addSubview:self.uploadView];
        
        self.uploadButton.frame = CGRectMake(0, JHeight - 40, JWidth, 40);
        [self.uploadView addSubview:self.uploadButton];
        
        [self.uploadAct setFrame:CGRectMake(JWidth/2 - 30, 20, 60, 60)];
        [self.uploadAct setCenter:CGPointMake(JWidth/2, 50)];//指定进度轮中心点
        [self.uploadView addSubview:self.uploadAct];
        
        self.uploadLabel.frame = CGRectMake(0, 80, JWidth, 20);
        [self.uploadView addSubview:self.uploadLabel];
    }
    [self.uploadAct startAnimating];
    self.uploadLabel.text = @"正在上传";
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 10.f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    [manager POST:url parameters:@{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        if(image)
        {
            NSData * imageData = UIImageJPEGRepresentation(image,0.5);
            [formData appendPartWithFileData:imageData name:@"myfiles" fileName:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] mimeType:@"image/png"];
        }else{
            NSLog(@"照片为空");
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
        self.uploadLabel.text = @"上传成功";
        [self.uploadAct stopAnimating];
        [self performSelector:@selector(uploadImageOverMotherd) withObject:nil afterDelay:0.5];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"上传失败 %@", error);
        self.uploadLabel.text = @"上传失败";
        [self.uploadAct stopAnimating];
    }];
    
}
-(void)uploadImageOverMotherd{
    
    [self.uploadView removeFromSuperview];
}
-(UIView *)uploadView{
    
    if (!_uploadView) {
        _uploadView = [UIView new];
        _uploadView.backgroundColor = [UIColor whiteColor];
    }
    return _uploadView;
}
-(UILabel *)uploadLabel{
    
    if (!_uploadLabel) {
        _uploadLabel = [UILabel new];
        [_uploadLabel setTextAlignment:NSTextAlignmentCenter];
        _uploadLabel.font = [UIFont systemFontOfSize:21];
    }
    return _uploadLabel;
}
-(UIButton *)uploadButton{
    
    if (!_uploadButton) {
        _uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_uploadButton setTitle:@"完成" forState:UIControlStateNormal];
        [_uploadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_uploadButton addTarget:self action:@selector(uploadOver) forControlEvents:UIControlEventTouchUpInside];
        _uploadButton.backgroundColor = [UIColor yellowColor];
    }
    return _uploadButton;
}
-(UIActivityIndicatorView *)uploadAct{
    
    if (!_uploadAct) {
        _uploadAct = [[UIActivityIndicatorView alloc] init];
         [_uploadAct setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];//设置进度轮显示类型
    }
    return _uploadAct;
}
-(void)uploadOver{
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
