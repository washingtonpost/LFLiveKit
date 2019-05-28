//
//  VideoEncoding.h
//  LiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoFrame.h"
#import "LiveVideoConfiguration.h"

@protocol VideoEncoding;
/// 编码器编码后回调
@protocol VideoEncodingDelegate <NSObject>
@required
- (void)videoEncoder:(nullable id<VideoEncoding>)encoder videoFrame:(nullable VideoFrame *)frame;
@end

/// 编码器抽象的接口
@protocol VideoEncoding <NSObject>
@required
- (void)encodeVideoData:(nullable CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp;
@optional
@property (nonatomic, assign) NSInteger videoBitRate;
- (nullable instancetype)initWithVideoStreamConfiguration:(nullable LiveVideoConfiguration *)configuration;
- (void)setDelegate:(nullable id<VideoEncodingDelegate>)delegate;
- (void)stopEncoder;
@end

