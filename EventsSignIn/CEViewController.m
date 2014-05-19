//
//  CEViewController.m
//  EventsSignIn
//
//  Created by hjue on 5/19/14.
//  Copyright (c) 2014 CSDN. All rights reserved.
//

#import "CEViewController.h"
@import AVFoundation;
#import "SCShapeView.h"
#import "CEMemberList.h"
#import "ReactiveCocoa.h"

@interface CEViewController ()<AVCaptureMetadataOutputObjectsDelegate> {
    AVCaptureVideoPreviewLayer *_previewLayer;
    SCShapeView *_boundingBox;
    NSTimer *_boxHideTimer;
    UILabel *_decodedMessage;
    NSArray * _memberList;
    NSMutableArray * _usedMemberList;
    CEMemberList * _ceMemberList;
    AVCaptureSession *session ;
    BOOL locked;
}

@end

@implementation CEViewController

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    locked = NO;
    _ceMemberList = [[CEMemberList alloc]init];
    if (!_memberList) {
        _memberList = [_ceMemberList memberList];        
    }

    if (!_usedMemberList) {
        _usedMemberList = [[_ceMemberList usedMemberList] mutableCopy];
    }

    
    // Create a new AVCaptureSession
    session = [[AVCaptureSession alloc] init];

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    // Want the normal device
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if(input) {
        // Add the input to the session
        [session addInput:input];
    } else {
        NSLog(@"error: %@", error);
        return;
    }
    
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    // Have to add the output before setting metadata types
    [session addOutput:output];
    // What different things can we register to recognise?
    NSLog(@"%@", [output availableMetadataObjectTypes]);
    // We're only interested in QR Codes
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    // This VC is the delegate. Please call us on the main queue
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Display on screen
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.bounds = self.view.bounds;
    _previewLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    [self.view.layer addSublayer:_previewLayer];
    
    
    // Add the view to draw the bounding box for the UIView
    _boundingBox = [[SCShapeView alloc] initWithFrame:self.view.bounds];
    _boundingBox.backgroundColor = [UIColor clearColor];
    _boundingBox.hidden = YES;
    [self.view addSubview:_boundingBox];
    
    // Add a label to display the resultant message
    _decodedMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 75, CGRectGetWidth(self.view.bounds), 75)];
    _decodedMessage.numberOfLines = 0;
    _decodedMessage.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.9];
    _decodedMessage.textColor = [UIColor darkGrayColor];
    _decodedMessage.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_decodedMessage];
    
    // Start the AVSession running
    [session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (locked) {
        return;
    }
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            // Transform the meta-data coordinates to screen coords
            AVMetadataMachineReadableCodeObject *transformed = (AVMetadataMachineReadableCodeObject *)[_previewLayer transformedMetadataObjectForMetadataObject:metadata];
            // Update the frame on the _boundingBox view, and show it
            _boundingBox.frame = transformed.bounds;
            _boundingBox.hidden = NO;
            // Now convert the corners array into CGPoints in the coordinate system
            //  of the bounding box itself
            NSArray *translatedCorners = [self translatePoints:transformed.corners
                                                      fromView:self.view
                                                        toView:_boundingBox];
            
            // Set the corners array
            _boundingBox.corners = translatedCorners;
            
            // Update the view with the decoded text
            NSString * qrcode  = [transformed stringValue];
            NSString * message = qrcode;
            if (qrcode.length>5) {
                NSArray *matches = [_memberList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF matches[c] %@",qrcode]];
                if ([matches count]>0) {
                    NSArray *matches_used = [_usedMemberList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF matches[c] %@",qrcode]];
                    if ([matches_used count]>0) {
                        message = [NSString stringWithFormat:@"%@ 已使用！",qrcode];
                        [session stopRunning];
                        locked = YES;
                        
                        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:message message:nil delegate:nil
                    cancelButtonTitle:nil otherButtonTitles:@"确认", nil];
                        [[alertView rac_buttonClickedSignal]subscribeNext:^(id x) {
                            NSLog(@"alertView:%d",[x intValue]) ;
                            [session startRunning];
                            locked = NO;
                        }];
                        [alertView show];
                        
                    }else{
                        message = [NSString stringWithFormat:@"%@ 签到成功！",qrcode];
                        [_usedMemberList addObject:qrcode];
                        [_ceMemberList appendUsedMemberList:_usedMemberList];
                        [session stopRunning];
                        locked = YES;
                        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:message message:nil delegate:nil
                                                                 cancelButtonTitle:nil otherButtonTitles:@"确认", nil];
                        [[alertView rac_buttonClickedSignal]subscribeNext:^(id x) {
                            NSLog(@"alertView:%d",[x intValue]) ;
                            locked = NO;
                            [session startRunning];
                        }];
                        [alertView show];

                    }
                }else{
                    message = [NSString stringWithFormat:@"%@ 没有找到！",qrcode];
                }
                NSLog(@"message:%@",message);
            }
            _decodedMessage.text = message;
            
            // Start the timer which will hide the overlay
            [self startOverlayHideTimer];
        }
    }
}

#pragma mark - Utility Methods
- (void)startOverlayHideTimer
{
    // Cancel it if we're already running
    if(_boxHideTimer) {
        [_boxHideTimer invalidate];
    }
    
    // Restart it to hide the overlay when it fires
    _boxHideTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                     target:self
                                                   selector:@selector(removeBoundingBox:)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)removeBoundingBox:(id)sender
{
    // Hide the box and remove the decoded text
    _boundingBox.hidden = YES;
    _decodedMessage.text = @"";
}

- (NSArray *)translatePoints:(NSArray *)points fromView:(UIView *)fromView toView:(UIView *)toView
{
    NSMutableArray *translatedPoints = [NSMutableArray new];
    
    // The points are provided in a dictionary with keys X and Y
    for (NSDictionary *point in points) {
        // Let's turn them into CGPoints
        CGPoint pointValue = CGPointMake([point[@"X"] floatValue], [point[@"Y"] floatValue]);
        // Now translate from one view to the other
        CGPoint translatedPoint = [fromView convertPoint:pointValue toView:toView];
        // Box them up and add to the array
        [translatedPoints addObject:[NSValue valueWithCGPoint:translatedPoint]];
    }
    
    return [translatedPoints copy];
}

@end
