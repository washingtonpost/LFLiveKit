//
//  AudioCapture.h
//  LiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LiveAudioConfiguration.h"

#pragma mark -- AudioCaptureNotification
/** compoentFialed will post the notification */
extern NSString *_Nullable const AudioComponentFailedToCreateNotification;

@class AudioCapture;
/** AudioCapture callback audioData */
@protocol AudioCaptureDelegate <NSObject>
- (void)captureOutput:(nullable AudioCapture *)capture audioData:(nullable NSData*)audioData;
@end


@interface AudioCapture : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<AudioCaptureDelegate> delegate;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

#pragma mark - Initializer

/**
   The designated initializer. Multiple instances with the same configuration will make the
   capture unstable.
 */
- (nullable instancetype)initWithAudioConfiguration:(nullable LiveAudioConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)init NS_UNAVAILABLE;

@end
