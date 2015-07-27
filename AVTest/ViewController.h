//
//  ViewController.h
//  AVTest
//
//  Created by Andrew Pang on 7/19/15.
//  Copyright (c) 2015 andrewpang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController{
    IBOutlet UIView *frameForCapture;
    
}

@property(nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) dispatch_queue_t queue;
//- (IBAction)takePhoto:(id)sender;


@end

