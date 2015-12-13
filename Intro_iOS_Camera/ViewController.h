//
//  ViewController.h
//  LK_v5
//
//  Created by Siddhant Wadhwa on 12/4/15.
//  Copyright © 2015 Siddhant Wadhwa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPUserResizableView.h"

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import "opencv2/highgui.hpp"
#endif

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate,SPUserResizableViewDelegate>

- (IBAction)takePhoto:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *template_label;
@property (weak, nonatomic) IBOutlet UIImageView *template_window;

@end

