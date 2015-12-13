//
//  ViewController.m
//  LK_v5
//
//  Created by Siddhant Wadhwa on 12/4/15.
//  Copyright © 2015 Siddhant Wadhwa. All rights reserved.
//

#import "ViewController.h"
#import "SPUserResizableView.h"
#import <AVFoundation/AVFoundation.h>

// Include stdlib.h and std namespace so we can mix C++ code in here
#include <stdlib.h>
//#include <bitplanes/core/config.h>
#include <bitplanes/core/algorithm_parameters.h>
#include <bitplanes/core/bitplanes_tracker_pyramid.h>
#include <bitplanes/core/homography.h>
#include <bitplanes/core/homography.h>
#include <bitplanes/utils/timer.h>
#include <bitplanes/core/viz.h>

@interface ViewController ()

@end

@implementation ViewController
AVCaptureSession *session;
AVCaptureStillImageOutput *stillImageOutput;
float imageWidth = 640;
float imageHeight = 480;
BOOL hasTemplate = NO;
cv::Rect templateBox;
cv::Mat template_mat;
bp::BitPlanesTrackerPyramid<bp::Homography> *tracker;
UIImage *temp;
BOOL available = YES;
AVCaptureVideoPreviewLayer *previewLayer;
SPUserResizableView *userResizableView;
UIImageView *tracked_view;
bp::Result result;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    hasTemplate = NO;
    available = YES;
    
    self.template_label.hidden=true;
    self.template_window.hidden=true;
    
    // Initializing the tracker
    bp::AlgorithmParameters params;
    params.num_levels = 3;
    params.max_iterations = 10;
    params.parameter_tolerance = 5e-56;
    params.function_tolerance = 1e-55;
    params.verbose = false;
    tracker = new bp::BitPlanesTrackerPyramid<bp::Homography>(params);
    
    // Initializing subviews and windows to display tracking results
    tracked_view = [[UIImageView alloc] initWithFrame:self.view.frame];
    tracked_view.hidden=true;
    [self.view addSubview:tracked_view];
    [self.view addSubview:self.template_window];
    [self.view addSubview:_template_label];
    
    // Initializing the AVCaptureSession
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPreset640x480];
    
    // Initializing the AVCapture Input Device
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [inputDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
    //[inputDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 30)];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    if ([session canAddInput:deviceInput]) {
        [session addInput:deviceInput];
    }
    
    // Initializing the Camera Preview Layer
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    previewLayer.hidden=false;
    
    // Inserting Camera Preview Layer into the view
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.view.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    // Intialinzing and adding userResizableView to select bounds
    // for the template bounding box
    userResizableView = [[SPUserResizableView alloc] initWithFrame:frame];
    UIView *contentView = [[UIView alloc] initWithFrame:frame];
    userResizableView.contentView = contentView;
    userResizableView.delegate = self;
    [self.view addSubview:userResizableView];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    //dispatch_release(queue);
    
    // Specify the pixel format and other video settings
    output.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    //output.minFrameDuration = CMTimeMake(1, 30);
    output.alwaysDiscardsLateVideoFrames=YES;
    
    // Specify still photo settings and add photo output
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    [session addOutput:stillImageOutput];
    
    [session startRunning];
}


- (void)userResizableViewDidEndEditing:(SPUserResizableView *)userResizableView
{
    float w = userResizableView.contentView.frame.size.width;
    float h = userResizableView.contentView.frame.size.height;
    
    // imageWidth and imageHeight are known in advance when the camera is initialized
    float wX = imageWidth / (float) self.view.frame.size.width;
    float wY = imageHeight / (float) self.view.frame.size.height;
    
    float x = userResizableView.center.x - w / 2.0;
    float y = userResizableView.center.y - h / 2.0;
    
    if(!hasTemplate) { // template has not yet been set
        templateBox = cv::Rect(x*wX, y*wY, ceil(w*wX), ceil(h*wY));
        NSLog(@"templateBox set to : (%f, %f, %f, %f)", x*wX, y*wY, ceil(w*wX), ceil(h*wY));
    }
    
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if(YES) {
        // Block Mutex
        available = NO;
        
        // Create a UIImage from the sample buffer data
        //UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
        //NSLog(@"Samplebuffer written");
        cv::Mat color = [self cvMatFromUIImage:[self imageFromSampleBuffer:sampleBuffer]];
        cv::Mat gray;
        //dispatch_sync(dispatch_get_main_queue(), ^{
        cv::cvtColor(color, gray, CV_BGRA2GRAY);
        //});
        
        // track in case the template has been set
        if(hasTemplate){
            
            dispatch_sync(dispatch_get_main_queue(), ^{
            result = tracker->track(gray);
            });
            bp::DrawTrackingResult(color, color, templateBox, result.T.data());
            
            }
        
        // Send output of tracking results to tracked_view
        //image = [self UIImageFromCVMat:color];
        dispatch_async(dispatch_get_main_queue(), ^{
        [tracked_view setImage:[self UIImageFromCVMat:color]]; // Run in main thread (UI thread)
        });
        
        // Release mutex
        available=YES;
    }
}

// Called when the 'Set Template' button is pressed, and the still photo is to be captured
- (IBAction)takePhoto:(id)sender {
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        for (AVCaptureInputPort *port in [ connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            [self processTemplate:image];
        }
    }];
}

// Called when the still photo is taken and the template is to be set
- (void)processTemplate:(UIImage *)image_in {
    cv::Mat template_color = [self cvMatFromUIImage:image_in];
    cv::cvtColor(template_color, template_mat, CV_BGRA2GRAY);
    tracker->setTemplate(template_mat, templateBox);
    
    // Set image to be displayed in the template display window
    cv::Mat temp_window;
    bp::Matrix33f T(bp::Matrix33f::Identity());
    bp::DrawTrackingResult(temp_window, template_mat, templateBox, T.data());
    UIImage *temp_window_UI = [self UIImageFromCVMat:temp_window];
    
    // Reset hidden flags and send output to template window
    self.template_label.hidden=false;
    self.template_window.hidden=false;
    self.template_window.image = temp_window_UI;
    userResizableView.hidden=true;
    previewLayer.hidden=true;
    tracked_view.hidden=false;
    hasTemplate=YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//
// HELPER FUNCTIONS FOR CONVERTING BETWEEN UIIMAGE AND CV_MATTYPES
//

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

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}
@end
