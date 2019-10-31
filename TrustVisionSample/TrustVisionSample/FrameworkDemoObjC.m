//
//  FrameworkDemoObjC.m
//  TrustVisionSample
//
//  Created by Nguyen Vu on 10/3/19.
//  Copyright © 2019 MACBOOK. All rights reserved.
//

#import "FrameworkDemoObjC.h"
#import <Foundation/Foundation.h>
#import "TrustVisionSample-Bridging-Header.h"

@implementation FrameworkDemoObjC

- (void)startFlowWithViewController: (UIViewController *)vc {
    NSString *accessKeyId = @"ddac2562-3bd0-41ef-93a4-e527fc167c5a";
    NSString *accessKeySecret = @"97dc8a54-8bb7-476f-8636-9c4d0c403c23";
    
    [TrustVisionSdk initializeWithAccessKeyId: accessKeyId
                              accessKeySecret: accessKeySecret
                                     isForced: true
                                      success: ^() {
         NSError *error;
         NSArray<TVCardType *> *cardTypes = [TrustVisionSdk getCardTypesAndReturnError: &error];
         TVSDKConfig *config = [TVSDKConfig defaultConfig];
         [config setIsEnableSound:true];
         [config setLivenessMode:TVLivenessOptionPassive];
         [config setActionMode:ActionModeFaceMatching];
         [config setCardType:[cardTypes firstObject]];
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [self presentFlowWithConfig:config viewController:vc];
         });
     }
     failure: ^(TVError *error) {
         
     }];
}

- (void)presentFlowWithConfig: (TVSDKConfig *)config viewController: (UIViewController *)vc {
    NSError *error;
    UIViewController *newVc = [TrustVisionSdk newCameraViewControllerWithConfig:config
                                                           error:&error
                                                        callback:^(TVDetectionResult *result, TVError *error) {
                                                            NSLog(@"[SDK ERROR] %@", [error description]);
                                                            NSLog(@"[SDK RESULT] %@", result);
                                                        }];
    
    if (error != nil) {
        NSLog(@"[SDK ERROR] [start SDK flow] SDK is not initialised");
        return;
    }
    
    [vc presentViewController:newVc animated:false completion:^{
        //
    }];
}

@end
