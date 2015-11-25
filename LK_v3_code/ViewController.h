//
//  ViewController.h
//  Intro_iOS_Camera
//
//  Created by Simon Lucey on 9/7/15.
//  Copyright (c) 2015 CMU_16432. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import "opencv2/highgui.hpp"
#import <opencv2/videoio/cap_ios.h>
#endif

@interface ViewController : UIViewController<CvVideoCameraDelegate>
- (cv::Mat)cvMatFromUIImage:(UIImage *)image;
@end
