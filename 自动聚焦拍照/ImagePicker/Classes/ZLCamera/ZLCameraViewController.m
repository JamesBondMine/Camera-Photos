//
//  BQCamera.m
//  BQCommunity
//
//  Created by ZL on 14-9-11.
//  Copyright (c) 2014年 beiqing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <objc/message.h>
#import "ZLCameraViewController.h"
#import "ZLCameraImageView.h"
#import "ZLCameraView.h"
#import "LGPhoto.h"
#import "LGCameraImageView.h"
#import "Masonry.h"
#define JWidth [[UIScreen mainScreen]bounds].size.width
#define JHeight [[UIScreen mainScreen]bounds].size.height


typedef void(^codeBlock)();
static CGFloat ZLCameraColletionViewW = 100;
static CGFloat ZLCameraColletionViewPadding = 20;
static CGFloat BOTTOM_HEIGHT = 60;

@interface ZLCameraViewController ()
<
  UIActionSheetDelegate,
  UICollectionViewDataSource,
  UICollectionViewDelegate,
  AVCaptureMetadataOutputObjectsDelegate,
  ZLCameraImageViewDelegate,
  ZLCameraViewDelegate,
  LGPhotoPickerBrowserViewControllerDataSource,
  LGPhotoPickerBrowserViewControllerDelegate,
  LGCameraImageViewDelegate
>
{
    
    int timeOut;
    dispatch_source_t _countTimer;
}
@property (weak,nonatomic) ZLCameraView *caramView;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIViewController *currentViewController;

// Datas 
@property (strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) NSMutableDictionary *dictM;

// AVFoundation
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureStillImageOutput *captureOutput;
@property (strong, nonatomic) AVCaptureDevice *device;

@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;

@property (nonatomic, assign) XGImageOrientation imageOrientation;
@property (nonatomic, assign) NSInteger flashCameraState;

@property (nonatomic, strong) UIButton *flashBtn;

@property (nonatomic, assign) BOOL canTakePicture;

@property (nonatomic, assign) BOOL takePicture;
@property (nonatomic, strong)LGCameraImageView *Cameraview;
@end

@implementation ZLCameraViewController
// smoothAutoFocusSupported
#pragma mark - Getter
#pragma mark Data
- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self initialize];
    
    [self setup];
    
    if (self.session) {
        [self.session startRunning];
    }
    timeOut = 0;
    if (self.IsHandStyle) {//手动模式注册音量监听
        [self initAudioSession];
    }else{
        [self manageCountDown:self.allTime];
        
    }
}

/**
 *  添加计时线程
 */
- (void)manageCountDown:(int)count{
    timeOut = count;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _countTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_countTimer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_countTimer, ^{
        if(timeOut <= 0) {
            dispatch_source_cancel(_countTimer);
            dispatch_async(dispatch_get_main_queue(), ^{
                //[self takePhotosCancel];
            });
        }else {
            timeOut--;
            dispatch_async(dispatch_get_main_queue(), ^{
                int X = count - timeOut;
                int F = X % self.everyTime;
                if (F == 0) {
                    NSLog(@"拍照 ");
                    [self stillImageMotherd:nil];
                }
            });
        }
    });
    
    dispatch_resume(_countTimer);
}
#pragma mark 监听点击音量建  注册
-(void)initAudioSession{
    
    NSError * error;
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
   
}
#pragma mark 监听点击音量建
- (void)volumeChanged:(NSNotification *)notification
{
    NSLog(@"点击了音量键");
    
    [self stillImageMotherd:nil];
}


- (void) initialize
{
    //1.创建会话层
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    self.captureOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [self.captureOutput setOutputSettings:outputSettings];
    self.session = [[AVCaptureSession alloc]init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.session canAddInput:self.input])
    {
        [self.session addInput:self.input];
    }
    
    if ([self.session canAddOutput:_captureOutput])
    {
        [self.session addOutput:_captureOutput];
    }
    
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat viewHeight = self.view.bounds.size.height-100;
    self.preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = CGRectMake(0, 40,viewWidth, viewHeight);
    
    // ZLCameraView
    ZLCameraView * caramView = [[ZLCameraView alloc] initWithFrame:CGRectMake(0, 40, viewWidth, viewHeight)];
    caramView.backgroundColor = [UIColor clearColor];
    caramView.delegate = self;
    [self.view addSubview:caramView];
    [caramView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset = 0;
        make.bottom.offset = -60;
        make.top.offset = 25;
    }];
    [self.view.layer insertSublayer:self.preview atIndex:0];
    self.caramView = caramView;
    caramView.point=CGPointMake(0.56896551724137934, 0.43200000000000005);
    if (!self.IsHandStyle) {
        //[self cameraDidSelected:caramView];
    }
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat viewHeight = self.view.bounds.size.height-100;
    self.preview.frame = CGRectMake(0, 40,viewWidth, viewHeight);

}

//更改设备属性前一定要锁上
-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    //也可以直接用_videoDevice,但是下面这种更好
    AVCaptureDevice *captureDevice= [_input device];
    //AVCaptureDevice *captureDevice= self.device;
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁,意义是---进行修改期间,先锁定,防止多处同时修改
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (!lockAcquired) {
        NSLog(@"锁定设备过程error，错误信息：%@",error.localizedDescription);
    }else{
        [_session beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [_session commitConfiguration];
    }
}

// 点击屏幕，触发聚焦
- (void)cameraDidSelected:(ZLCameraView *)camera{

    // 当设置完成之后，需要回调到上面那个方法⬆️
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
    
        // 触摸屏幕的坐标点需要转换成0-1，设置聚焦点
        CGPoint cameraPoint=CGPointMake(0.56896551724137934, 0.43200000000000005);//[self.preview captureDevicePointOfInterestForPoint:camera.point];
        
        /*****必须先设定聚焦位置，在设定聚焦方式******/
        //聚焦点的位置
        if ([self.device isFocusPointOfInterestSupported]) {
            [self.device setFocusPointOfInterest:cameraPoint];
        }
        
        // 聚焦模式
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }else{
            NSLog(@"聚焦模式修改失败");
        }

        //曝光点的位置
        if ([self.device isExposurePointOfInterestSupported]) {
            [self.device setExposurePointOfInterest:cameraPoint];
        }
        
        //曝光模式
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }else{
            NSLog(@"曝光模式修改失败");
        }
        
        // 防止点击一次，多次聚焦，会连续拍多张照片
        self.canTakePicture = YES;
        
    }];
    
}

// 监听焦距发生改变
-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {

    if([keyPath isEqualToString:@"adjustingFocus"]){
        BOOL adjustingFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        // 0代表焦距不发生改变 1代表焦距改变
        if (adjustingFocus == 0) {
            // 判断图片的限制个数
            if ((self.images.count == 1 && self.cameraType == ZLCameraSingle) || !self.GraphRecognition || !self.canTakePicture) {
                return;
            }
            
            // 点击一次可能会聚一次焦，也有可能会聚两次焦。一次聚焦，图像清晰。如果聚两次焦，照片会在第二次没有聚焦完成拍照，应为第一次聚焦完成会触发拍照，而拍照时间在第二次未聚焦完成，图像不清晰。增加延时可以让每次都是聚焦完成的时间点
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [NSThread sleepForTimeInterval:0.2];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self stillImageMotherd:nil];
                });
            });
        }

    }
}
// 隐藏和显示状态栏
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    AVCaptureDevice *camDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    int flags =NSKeyValueObservingOptionNew;
    [camDevice addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    // 恢复相机摸模式
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }else{
            NSLog(@"聚焦模式修改失败");
        }
        
        //曝光模式
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }else{
            NSLog(@"曝光模式修改失败");
        }
        
    }];
    AVCaptureDevice*camDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [camDevice removeObserver:self forKeyPath:@"adjustingFocus"];
}
-(BOOL)prefersStatusBarHidden
{
    return YES;
}
#pragma mark 初始化按钮
- (UIButton *) setupButtonWithImageName : (NSString *) imageName andX : (CGFloat ) x{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setTitle:@"翻转" forState:UIControlStateNormal];
    button.width = 80;
    button.y = 0;
    button.height = self.topView.height;
    button.x = x;
    [self.view addSubview:button];
    
    NSLog(@"nslog bug is shouw essay  nothing is posible buwan ");
    return button;
}



#pragma mark -初始化界面
- (void) setup{
    CGFloat width = 50;
    CGFloat margin = 20;
    
    UIView *topView = [[UIView alloc] init];
    topView.backgroundColor = [UIColor blackColor];
    topView.frame = CGRectMake(0, 0, self.view.width, 40);
    [self.view addSubview:topView];
    self.topView = topView;

    // 头部View
    UIButton * deviceBtn = [self setupButtonWithImageName:@"xiang.png" andX:self.view.width - margin - width];
    [deviceBtn addTarget:self action:@selector(changeCameraDevice:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * flashBtn = [self setupButtonWithImageName:@"shanguangdeng2.png" andX:10];
    [flashBtn addTarget:self action:@selector(flashCameraDevice:) forControlEvents:UIControlEventTouchUpInside];
    [flashBtn setTitle:@"关闭" forState:UIControlStateNormal];
    _flashBtn = flashBtn;
    _flashBtn.hidden = YES;
    
    // 底部View
    UIView * controlView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height-BOTTOM_HEIGHT, self.view.width, BOTTOM_HEIGHT)];
    controlView.backgroundColor = [UIColor blackColor];
    controlView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.controlView = controlView;
    [self.view addSubview:controlView];
    [controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.offset = 0;
        make.height.offset = BOTTOM_HEIGHT;
    }];

    UIView *contentView = [[UIView alloc] init];
    contentView.frame = controlView.bounds;
    contentView.backgroundColor = [UIColor blackColor];
    contentView.alpha = 0.3;
    [controlView addSubview:contentView];
    
    CGFloat x = (self.view.width - width) / 3;
    //取消
    UIButton *cancalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancalBtn.frame = CGRectMake(0, 0, x, controlView.height);
    [cancalBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancalBtn addTarget:self action:@selector(takePhotosCancel) forControlEvents:UIControlEventTouchUpInside];
    [controlView addSubview:cancalBtn];
    [cancalBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.offset = x;
        make.height.offset = controlView.height;
        make.left.top.offset = 0;
    }];
    
//    //拍照
//    UIButton * cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    cameraBtn.frame = CGRectMake(JWidth/2 - 40, JHeight - 120, 80,80);
//    cameraBtn.showsTouchWhenHighlighted = YES;
//    cameraBtn.layer.masksToBounds = YES;
//    cameraBtn.layer.cornerRadius = 40;
//    [cameraBtn setTitle:@"拍照" forState:UIControlStateNormal];
//    cameraBtn.backgroundColor = [UIColor redColor];
//    cameraBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    [cameraBtn setImage:[UIImage imageNamed:@"paizhao.png"] forState:UIControlStateNormal];
//    [cameraBtn addTarget:self action:@selector(stillImageMotherd:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:cameraBtn];
//    //cameraBtn.hidden = self.GraphRecognition;
    

}

- (LGPhotoPickerBrowserPhoto *) photoBrowser:(LGPhotoPickerBrowserViewController *)pickerBrowser photoAtIndexPath:(NSIndexPath *)indexPath{
    
    id imageObj = [[self.images objectAtIndex:indexPath.row] photoImage];
    LGPhotoPickerBrowserPhoto *photo = [LGPhotoPickerBrowserPhoto photoAnyImageObjWith:imageObj];
    
    UICollectionViewCell *cell = (UICollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    
    UIImageView *imageView = [[cell.contentView subviews] lastObject];
    photo.toView = imageView;
    photo.thumbImage = imageView.image;
    
    return photo;
}

- (void)deleteImageView:(ZLCameraImageView *)imageView{
    NSMutableArray *arrM = [self.images mutableCopy];
    for (ZLCamera *camera in self.images) {
        UIImage *image = camera.thumbImage;
        if ([image isEqual:imageView.image]) {
            [arrM removeObject:camera];
        }
    }
    self.images = arrM;
    [self.collectionView reloadData];
}

- (void)showPickerVc:(UIViewController *)vc{
    __weak typeof(vc)weakVc = vc;
    if (weakVc != nil) {
        [weakVc presentViewController:self animated:YES completion:nil];
    }
}
#pragma mark   拍照出zhaopiande方法
-(void)Captureimage
{
    AVCaptureConnection * videoConnection = nil;
    for (AVCaptureConnection *connection in self.captureOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    __weak typeof(self) WeakSelf = self;
    [self.captureOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *t_image = [UIImage imageWithData:imageData];
         t_image = [WeakSelf cutImage:t_image];
         t_image = [WeakSelf fixOrientation:t_image];
         NSLog(@"拍照结束：%@",t_image);
         if (WeakSelf.cameraType == ZLCameraSingle) {
             [WeakSelf.images removeAllObjects];
             [WeakSelf.images addObject:t_image];
         } else{
             [WeakSelf.images addObject:t_image];
         }
         [WeakSelf.delegete takePhotos:WeakSelf.images];
         if (WeakSelf.images.count == WeakSelf.count && !self.IsHandStyle) {
             [WeakSelf dismissViewControllerAnimated:NO completion:nil];
         }
         [_Cameraview doneAction];
     }];

}

//裁剪image
- (UIImage *)cutImage:(UIImage *)srcImg {
    //注意：这个rect是指横屏时的rect，即屏幕对着自己，home建在右边
    CGRect rect = CGRectMake((srcImg.size.height / CGRectGetHeight(self.view.frame)) * 70, 0, srcImg.size.width * 1.33, srcImg.size.width);
    CGImageRef subImageRef = CGImageCreateWithImageInRect(srcImg.CGImage, rect);
    CGFloat subWidth = CGImageGetWidth(subImageRef);
    CGFloat subHeight = CGImageGetHeight(subImageRef);
    CGRect smallBounds = CGRectMake(0, 0, subWidth, subHeight);
    //旋转后，画出来
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, 0, subWidth);
    transform = CGAffineTransformRotate(transform, -M_PI_2);
    CGContextRef ctx = CGBitmapContextCreate(NULL, subHeight, subWidth,
                                             CGImageGetBitsPerComponent(subImageRef), 0,
                                             CGImageGetColorSpace(subImageRef),
                                             CGImageGetBitmapInfo(subImageRef));
    CGContextConcatCTM(ctx, transform);
    CGContextDrawImage(ctx, smallBounds, subImageRef);
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;

}

//旋转image
- (UIImage *)fixOrientation:(UIImage *)srcImg
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGFloat width = srcImg.size.width;
    CGFloat height = srcImg.size.height;
    
    CGContextRef ctx;
    
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown: //竖屏，不旋转
            ctx = CGBitmapContextCreate(NULL, width, height,
                                        CGImageGetBitsPerComponent(srcImg.CGImage), 0,
                                        CGImageGetColorSpace(srcImg.CGImage),
                                        CGImageGetBitmapInfo(srcImg.CGImage));
            break;
            
        case UIDeviceOrientationLandscapeLeft:  //横屏，home键在右手边，逆时针旋转90°
            transform = CGAffineTransformTranslate(transform, height, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            ctx = CGBitmapContextCreate(NULL, height, width,
                                        CGImageGetBitsPerComponent(srcImg.CGImage), 0,
                                        CGImageGetColorSpace(srcImg.CGImage),
                                        CGImageGetBitmapInfo(srcImg.CGImage));
            break;
            
        case UIDeviceOrientationLandscapeRight:  //横屏，home键在左手边，顺时针旋转90°
            transform = CGAffineTransformTranslate(transform, 0, width);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            ctx = CGBitmapContextCreate(NULL, height, width,
                                        CGImageGetBitsPerComponent(srcImg.CGImage), 0,
                                        CGImageGetColorSpace(srcImg.CGImage),
                                        CGImageGetBitmapInfo(srcImg.CGImage));
            break;
            
        default:
            break;
    }
    
    CGContextConcatCTM(ctx, transform);
    CGContextDrawImage(ctx, CGRectMake(0,0,width,height), srcImg.CGImage);
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    
    
    return img;
}

//LG
- (void)displayImage:(UIImage *)images {
    _Cameraview = [[LGCameraImageView alloc] initWithFrame:self.view.frame];
    _Cameraview.delegate = self;
    _Cameraview.imageOrientation = _imageOrientation;
    _Cameraview.imageToDisplay = images;
    [self.view addSubview:_Cameraview];
    
}

-(void)CaptureStillImage
{
    [self  Captureimage];
    // 一次拍完照片，才允许可以拍照
    self.canTakePicture = NO;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

- (void)changeCameraDevice:(id)sender
{
    // 翻转
    [UIView beginAnimations:@"animation" context:nil];
    [UIView setAnimationDuration:.5f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
    [UIView commitAnimations];
    
    NSArray *inputs = self.session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            else
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            [self.session beginConfiguration];
            
            [self.session removeInput:input];
            [self.session addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.session commitConfiguration];
            break;
        }
    }
}

- (void) flashLightModel : (codeBlock) codeBlock{
    if (!codeBlock){
        return;
    }else{
        [self.session beginConfiguration];
        [self.device lockForConfiguration:nil];
        codeBlock();
        [self.device unlockForConfiguration];
        [self.session commitConfiguration];
        [self.session startRunning];
        
    }
}
- (void) flashCameraDevice:(UIButton *)sender{
    if (_flashCameraState < 0) {
        _flashCameraState = 0;
    }
    _flashCameraState ++;
    if (_flashCameraState >= 4) {
        _flashCameraState = 0;
    }
    AVCaptureFlashMode mode;
    
    switch (_flashCameraState) {
        case 1:
            mode = AVCaptureFlashModeOn;
            [_flashBtn setTitle:@"打开" forState:UIControlStateNormal];
            break;
        case 2:
            mode = AVCaptureFlashModeAuto;
            [_flashBtn setTitle:@"自动" forState:UIControlStateNormal];
            break;
        case 3:
            mode = AVCaptureFlashModeOff;
            [_flashBtn setTitle:@"关闭" forState:UIControlStateNormal];
            break;
        default:
            mode = AVCaptureFlashModeOff;
            [_flashBtn setTitle:@"关闭" forState:UIControlStateNormal];
            break;
    }
    if ([self.device isFlashModeSupported:mode])
    {
        [self flashLightModel:^{
            //[self.device setFlashMode:mode];
        }];
    }
}

- (void)takePhotosCancel
{
    [self dismissViewControllerAnimated:NO completion:nil];

}

//拍照
- (void)stillImageMotherd:(id)sender
{

    [self Captureimage];
    self.canTakePicture = NO;
  
}

- (BOOL)shouldAutorotate{
    return YES;
}

#pragma mark - 屏幕
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskPortrait;
    
}
// 支持屏幕旋转
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return NO;
}
// 画面一开始加载时就是竖向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - XGCameraImageViewDelegate
- (void)xgCameraImageViewSendBtnTouched {
    [self takePhotosDoneAction];
}

- (void)xgCameraImageViewCancleBtnTouched {
    [self.images removeAllObjects];
}
//完成、取消
- (void)takePhotosDoneAction
{

    [self takePhotosCancel];
}

- (void)dealloc{
    NSLog(@"%s", __FUNCTION__);
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}
- (NSMutableArray *)images{
    if (!_images) {
        _images = [NSMutableArray array];
    }
    return _images;
}

- (NSMutableDictionary *)dictM{
    if (!_dictM) {
        _dictM = [NSMutableDictionary dictionary];
    }
    return _dictM;
}
@end

