//
//  ViewController.m
//  AVTest
//
//  Created by Andrew Pang on 7/19/15.
//  Copyright (c) 2015 andrewpang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>

@interface ViewController ()

@end

@implementation ViewController

AVCaptureSession *session;
CGRect frame;
AVCaptureStillImageOutput *stillImageOutput;
bool saveImage = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self setupCaptureSession];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Create and configure a capture session and start it running
- (void)setupCaptureSession
{
    NSError *error = nil;
    
    // Create the session
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset: AVCaptureSessionPresetPhoto];
    
//    AVCaptureVideoOrientation avcaptureOrientation;
//    avcaptureOrientation = AVCaptureVideoOrientationPortrait;
//    [self setOrientation:avcaptureOrientation];
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice
                               defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    if ([session canAddInput:input]) {
        [device lockForConfiguration:&error];
        
        device.activeVideoMinFrameDuration = CMTimeMake(1, 2);
        device.activeVideoMaxFrameDuration = CMTimeMake(1, 2);

        [session addInput:input];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    frame = frameForCapture.frame;
    
    [previewLayer setFrame: frame];
    
    [rootLayer insertSublayer:previewLayer atIndex: 0];

    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue;
    queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:(id)self queue:queue];
    //dispatch_release(queue);

    // Setup the still image file output
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
    
    if ([session canAddOutput:stillImageOutput]) {
        [session addOutput:stillImageOutput];
    }

 
    
    // Specify the pixel format
    output.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];

    
    // Start the session running to start the flow of data
    [session startRunning];
}

- ( void ) captureOutput: ( AVCaptureOutput * ) captureOutput
   didOutputSampleBuffer: ( CMSampleBufferRef ) sampleBuffer
          fromConnection: ( AVCaptureConnection * ) connection
{
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    if(saveImage == true){
        NSLog(@"hey");
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
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
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    return (image);
}

-(IBAction)captureNow {
    if(saveImage == NO){
        saveImage = YES;
    }
    else
        saveImage = NO;
//    AVCaptureConnection *videoConnection = nil;
//    for (AVCaptureConnection *connection in stillImageOutput.connections)
//    {
//        for (AVCaptureInputPort *port in [connection inputPorts])
//        {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
//            {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection)
//        {
//            break;
//        }
//    }
//    
//    NSLog(@"about to request a capture from: %@", stillImageOutput);
}
     
//     captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
//     {
//         CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
//         if (exifAttachments)
//         {
//             // Do something with the attachments.
//             NSLog(@"attachements: %@", exifAttachments);
//         } else {
//             NSLog(@"no attachments");
//         }
//         
//         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
//         UIImage *image = [[UIImage alloc] initWithData:imageData];
//         
//         UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
//     }];
//}




@end
