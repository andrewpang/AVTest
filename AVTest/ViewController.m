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
NSMutableArray *images;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewWillAppear:(BOOL)animated {
    images = [[NSMutableArray alloc] init];
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
        [images addObject: image];
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

-(void) writeImagesToMovieAtPath:(NSString *) path withSize:(CGSize) size
{
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4
                                                              error:&error];
    NSParameterAssert(videoWriter);
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //Video encoding
    CVPixelBufferRef buffer = NULL;
    //convert uiimage to CGImage.
    int frameCount = 0;
    for(int i = 0; i<[images count]; i++)
    {
        buffer = [self pixelBufferFromCGImage:[[images objectAtIndex:i] CGImage] size:size];
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp %d\n", frameCount, j);
                
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) 10);
                
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                CVPixelBufferPoolRef bufferPool = adaptor.pixelBufferPool;
                NSParameterAssert(bufferPool != NULL);
                
                [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok)
        {
            printf("error appending image %d times %d\n", frameCount, j);
        }
        frameCount++;
        CVBufferRelease(buffer);
    }
    
    [videoWriterInput markAsFinished];
    //[videoWriter finishWriting];
    
    //[videoWriterInput release];
    //[videoWriter release];
    
    [images removeAllObjects];
    
    NSLog(@"Write Ended"); 
}

- (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    status=status;//Added to make the stupid compiler not show a stupid warning.
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    //CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
    //CGContextScaleCTM(context, 1.0, -1.0);//Flip vertically to account for different origin
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}





@end
