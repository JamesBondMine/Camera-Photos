//
//  BQCamera.h
//  BQCommunity
//
//  Created by ZL on 14-9-11.
//  Copyright (c) 2014年 beiqing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZLCamera.h"


# pragma mark  拍照结束代理
@protocol JSTakePhotosDelegte <NSObject>;

-(void)takePhotos:(NSArray * )photosArray;

@end

typedef NS_ENUM(NSInteger, ZLCameraType) {
    ZLCameraSingle,//单张
    ZLCameraContinuous,//连拍
};
@interface ZLCameraViewController : UIViewController

/**
 * 总张数
 * 总时间
 * 每次时间
 */
@property (nonatomic,assign) int count,
allTime,
everyTime;//总张数


/**
 * 顶部View
 * 底部View
 */
@property (weak, nonatomic) UIView * topView,
* controlView;

@property (nonatomic,assign) BOOL IsHandStyle;  //是否手动
@property (assign,nonatomic) NSInteger maxCount;// 拍照的个数限制
@property (nonatomic, assign) ZLCameraType cameraType;// 单张还是连拍
@property (nonatomic,weak) id <JSTakePhotosDelegte> delegete;

// 是否是最新功能识别，最新功能比一般拍照，添加聚焦后自动拍照
@property (nonatomic, assign) BOOL GraphRecognition;

- (void)showPickerVc:(UIViewController *)vc;
@end
