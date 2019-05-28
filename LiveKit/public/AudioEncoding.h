//
//  AudioEncoding.h
//  LiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioFrame.h"
#import "LiveAudioConfiguration.h"



@protocol AudioEncoding;
/// 编码器编码后回调
@protocol AudioEncodingDelegate <NSObject>
@required
- (void)audioEncoder:(nullable id<AudioEncoding>)encoder audioFrame:(nullable AudioFrame *)frame;
@end

/// 编码器抽象的接口
@protocol AudioEncoding <NSObject>
@required
- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp;
- (void)stopEncoder;
@optional
- (nullable instancetype)initWithAudioStreamConfiguration:(nullable LiveAudioConfiguration *)configuration;
- (void)setDelegate:(nullable id<AudioEncodingDelegate>)delegate;
- (nullable NSData *)adtsData:(NSInteger)channel rawDataLength:(NSInteger)rawDataLength;
@end

