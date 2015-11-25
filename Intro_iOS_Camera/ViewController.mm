//
//  ViewController.m
//  Intro_iOS_Camera
//
//  Created by Simon Lucey on 9/7/15.
//  Copyright (c) 2015 CMU_16432. All rights reserved.
//

#import "ViewController.h"

// Include stdlib.h and std namespace so we can mix C++ code in here
#include <stdlib.h>
#include <bitplanes/core/config.h>
#include <bitplanes/core/algorithm_parameters.h>
#include <bitplanes/core/bitplanes_tracker_pyramid.h>
#include <bitplanes/core/homography.h>
#include <bitplanes/core/homography.h>
#include <bitplanes/utils/timer.h>
#include <bitplanes/core/viz.h>


using namespace std;

@interface ViewController()
{
    UIImageView *liveView_; // Live output from the camera
    UIImageView *overlay;
    UIImageView *resultView_; // Preview view of everything...
    UIButton *takephotoButton_, *goliveButton_, *clear_points_button; // Button to initiate OpenCV processing of image
    CvVideoCamera* videoCamera;
    vector<cv::Point2f> rect_pts;
    cv::Rect_<float> roi;
    cv::Rect roi_projected;
    cv::Scalar GREEN, BLUE;
    cv::Mat overlay_mask;
    int image_res_x, image_res_y;
    BOOL template_init, template_set;
    
    bp::BitPlanesTrackerPyramid<bp::Homography> *tracker;
}
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@end

@implementation ViewController


//===============================================================================================
// Setup view for excuting App
- (void)viewDidLoad {
    [super viewDidLoad];
    
    template_init = NO;
    template_set = NO;
    image_res_x=640;
    image_res_y=480;
    
    GREEN=cv::Scalar(255,255,0); // Set the GREEN color
    BLUE=cv::Scalar(0,0,255); // Set the GREEN color
    
    // Initializing the tracker
    bp::AlgorithmParameters params;
    params.num_levels = 3;
    params.max_iterations = 50;
    params.parameter_tolerance = 5e-6;
    params.function_tolerance = 1e-5;
    params.verbose = false;
    
    tracker = new bp::BitPlanesTrackerPyramid<bp::Homography>(params);
    
    // Do any additional setup after loading the view, typically from a nib.
    
    // 1. Setup the your OpenCV view, so it takes up the entire App screen......
    int view_width = self.view.frame.size.width;
    int view_height = self.view.frame.size.width;//(640*view_width)/480; // Work out the viw-height assuming 640x480 input
    int view_offset = 0;//(self.view.frame.size.height - view_height)/2;
    liveView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    overlay = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:liveView_]; // Important: add liveView_ as a subview
    [self.view addSubview:overlay];
    overlay.alpha = 0.2;
    
    // Initializing empty mask for overlay
    overlay_mask = cv::Mat::zeros(view_height, view_width, CV_8UC4);
    
    // Adding tap gesture recognizer
    UITapGestureRecognizer *press = [[UITapGestureRecognizer alloc]
                                     initWithTarget:self action:@selector(hasTapped:)];
    press.delegate = (id)self;
    [self.view addGestureRecognizer:press];
    
    resultView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:resultView_]; // Important: add resultView_ as a subview
    resultView_.hidden = true; // Hide the view
    
    // 2. First setup a button to take a single picture
    takephotoButton_ = [self simpleButton:@"Take Photo" buttonColor:[UIColor redColor] button_x_in:0];
    // Important part that connects the action to the member function buttonWasPressed
    [takephotoButton_ addTarget:self action:@selector(buttonWasPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // 3. Setup another button to go back to live video
    goliveButton_ = [self simpleButton:@"Go Live" buttonColor:[UIColor greenColor]  button_x_in:0];
    // Important part that connects the action to the member function buttonWasPressed
    [goliveButton_ addTarget:self action:@selector(liveWasPressed) forControlEvents:UIControlEventTouchUpInside];
    [goliveButton_ setHidden:true]; // Hide the button
    
    // Set up button to clear rect_pts
    clear_points_button = [self simpleButton:@"Clear Points" buttonColor:[UIColor blueColor]  button_x_in:20];
    [clear_points_button addTarget:self action:@selector(clear_points) forControlEvents:UIControlEventTouchUpInside];
    
    // 4. Initialize the camera parameters and start the camera (inside the App)
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:liveView_];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    // This starts the camera capture
    [self.videoCamera start];
    
}

- (void)processImage:(cv::Mat&)image;
{
    // Do some OpenCV stuff with the image
    cv::Mat image_copy;
    //cout<<"Channels :"<<image.channels()<<" "<<image.type()<<" size :"<<image.size()<<std::endl;
    cv::cvtColor(image, image_copy, CV_BGRA2GRAY);
    
    if(template_set)
    {
        auto result = tracker->track(image_copy);
        cout<<result<<endl;
        //template_set=NO;
        bp::Matrix33f T(bp::Matrix33f::Identity());
        bp::DrawTrackingResult(image_copy, image_copy, roi_projected, T.data());
    }
    
    if(template_init and rect_pts.size()>3)
    {
        bp::Timer timer;
        tracker->setTemplate(image_copy, roi_projected);
        cout<<roi_projected<<endl;
        template_init = NO; template_set =YES;
        auto t_ms=timer.stop().count();
        cout<<"time :"<<t_ms<<std::endl;
    }
    
    
    
    
    // invert image
    //cv::bitwise_not(image_copy, image_copy);
    //cv::cvtColor(image_copy, image, CV_BGRA2BGRA);
    image_copy.copyTo(image);
}


- (void)hasTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // handling code
        CGPoint tapPoint = [sender locationInView:self.view];
        NSLog(@"Long Press detected at %f, %f",tapPoint.x,tapPoint.y);
        
        cv::Point2f tmp_pt;
        tmp_pt.x = tapPoint.x;
        tmp_pt.y = tapPoint.y;		
        // Adding to rectangle vertices to be drawn and updating index
        rect_pts.push_back(tmp_pt);
        
        overlay_mask = cv::Scalar(0,0,0);
        overlay_mask = DrawPts(overlay_mask, rect_pts, GREEN);
        overlay_mask = DrawLines(overlay_mask, rect_pts, GREEN);
        [self form_rect];
        if(rect_pts.size()>3) cv::rectangle(overlay_mask, roi, BLUE, 3);
        overlay.image = [self UIImageFromCVMat:overlay_mask];
        
    }
}

// Quick function to draw points on an UIImage
cv::Mat DrawPts(cv::Mat &display_im, vector<cv::Point2f> &pts, const cv::Scalar &pts_clr)
{
    for(int i=0; i<pts.size(); i++) {
        cv::circle(display_im, pts[i], 3, pts_clr, 3); // Draw the points
        //cout<<"drawing pt : "<<pts[i];
    }
    return display_im; // Return the display image
}
// Quick function to draw lines on an UIImage
cv::Mat DrawLines(cv::Mat &display_im, vector<cv::Point2f> &pts, const cv::Scalar &pts_clr)
{
    for(int i=0; i<pts.size(); i++) {
        int j = i + 1; if(j == pts.size()) j = 0; // Go back to first point at the enbd
        cv::line(display_im, pts[i], pts[j], pts_clr, 2); // Draw the line
    }
    return display_im; // Return the display image
}

//===============================================================================================
// This member function is executed when the button is pressed
- (void)buttonWasPressed {
    [self.videoCamera start];
    [takephotoButton_ setHidden:true]; [goliveButton_ setHidden:false]; // Switch visibility of buttons
    [clear_points_button setHidden:true];
}
//===============================================================================================
// This member function is executed when the button is pressed
- (void)liveWasPressed {
    [takephotoButton_ setHidden:false]; [goliveButton_ setHidden:true]; // Switch visibility of buttons
    [clear_points_button setHidden:false];
    resultView_.hidden = true; // Hide the result view again
}
//===============================================================================================
// Simple member function to initialize buttons in the bottom of the screen so we do not have to
// bother with storyboard, and can go straight into vision on mobiles
//
- (UIButton *) simpleButton:(NSString *)buttonName buttonColor:(UIColor *)color button_x_in:(int)button_x
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom]; // Initialize the button
    // Bit of a hack, but just positions the button at the bottom of the screen
    int button_width = 200; int button_height = 50; // Set the button height and width (heuristic)
    // Botton position is adaptive as this could run on a different device (iPAD, iPhone, etc.)
    if(button_x==0) button_x = (self.view.frame.size.width - button_width)/2; // Position of top-left of button
    int button_y = self.view.frame.size.height - 80; // Position of top-left of button
    button.frame = CGRectMake(button_x, button_y, button_width, button_height); // Position the button
    [button setTitle:buttonName forState:UIControlStateNormal]; // Set the title for the button
    [button setTitleColor:color forState:UIControlStateNormal]; // Set the color for the title
    
    [self.view addSubview:button]; // Important: add the button as a subview
    //[button setEnabled:bflag]; [button setHidden:(!bflag)]; // Set visibility of the button
    return button; // Return the button pointer
}

//===============================================================================================
// Standard memory warning component added by Xcode
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clear_points {
    overlay_mask = cv::Scalar(0,0,0);
    overlay.image = [self UIImageFromCVMat:overlay_mask];
    rect_pts.clear();
    
}

- (void) form_rect {
    // variables for iterating
    float min_x, max_x, min_y, max_y;
    min_x=rect_pts[0].x; max_x=rect_pts[0].x;
    min_y=rect_pts[0].y, max_y=rect_pts[0].y;
    
    // finding point coordinate extremas
    for(int i=0; i<rect_pts.size(); i++) {
        cv::Point2f pt = rect_pts[i];
        min_x = MIN(pt.x, min_x);
        max_x = MAX(pt.x, max_x);
        min_y = MIN(pt.y, min_y);
        max_y = MAX(pt.y, max_y);
    }
    
    // setting global roi rect properties
    roi.x = min_x; roi.y = min_y;
    roi.width = max_x-min_x; roi.height = max_y-min_y;
    //cout<<"Roi:"<<roi<<std::endl;
    
    float w_x = image_res_x/1024.0;
    float w_y = image_res_y/768.0;
    
    roi_projected.x = roi.x*w_x;
    roi_projected.y = roi.y*w_y;
    roi_projected.width = roi.width*w_x;
    roi_projected.height = roi.height*w_y;
    
    template_init = YES;
    
    cout<<"Roi:"<<roi<<std::endl;
    cout<<"Roi_projected:"<<roi_projected<<std::endl;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end