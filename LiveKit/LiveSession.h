//
//  LiveSession.h
//  LiveKit
//
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LiveStreamInfo.h"
#import "AudioFrame.h"
#import "VideoFrame.h"
#import "LiveAudioConfiguration.h"
#import "LiveVideoConfiguration.h"
#import "LiveDebug.h"



typedef NS_ENUM(NSInteger,LiveCaptureType) {
    LiveCaptureAudio,         //< capture only audio
    LiveCaptureVideo,         //< capture onlt video
    LiveInputAudio,           //< only audio (External input audio)
    LiveInputVideo,           //< only video (External input video)
};


///< 用来控制采集类型（可以内部采集也可以外部传入等各种组合，支持单音频与单视频,外部输入适用于录屏，无人机等外设介入）
typedef NS_ENUM(NSInteger,LiveCaptureTypeMask) {
    LiveCaptureMaskAudio = (1 << LiveCaptureAudio),                                 ///< only inner capture audio (no video)
    LiveCaptureMaskVideo = (1 << LiveCaptureVideo),                                 ///< only inner capture video (no audio)
    LiveInputMaskAudio = (1 << LiveInputAudio),                                     ///< only outer input audio (no video)
    LiveInputMaskVideo = (1 << LiveInputVideo),                                     ///< only outer input video (no audio)
    LiveCaptureMaskAll = (LiveCaptureMaskAudio | LiveCaptureMaskVideo),           ///< inner capture audio and video
    LiveInputMaskAll = (LiveInputMaskAudio | LiveInputMaskVideo),                 ///< outer input audio and video(method see pushVideo and pushAudio)
    LiveCaptureMaskAudioInputVideo = (LiveCaptureMaskAudio | LiveInputMaskVideo), ///< inner capture audio and outer input video(method pushVideo and setRunning)
    LiveCaptureMaskVideoInputAudio = (LiveCaptureMaskVideo | LiveInputMaskAudio), ///< inner capture video and outer input audio(method pushAudio and setRunning)
    LiveCaptureDefaultMask = LiveCaptureMaskAll                                     ///< default is inner capture audio and video
};

@class LiveSession;
@protocol LiveSessionDelegate <NSObject>

@optional
/** live status changed will callback */
- (void)liveSession:(nullable LiveSession *)session liveStateDidChange:(LiveState)state;
/** live debug info callback */
- (void)liveSession:(nullable LiveSession *)session debugInfo:(nullable LiveDebug *)debugInfo;
/** callback socket errorcode */
- (void)liveSession:(nullable LiveSession *)session errorCode:(LiveSocketErrorCode)errorCode;
@end

@class LiveStreamInfo;

@interface LiveSession : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<LiveSessionDelegate> delegate;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

/** The preView will show OpenGL ES view*/
@property (nonatomic, strong, null_resettable) UIView *previewImageView;

/** The captureDevicePosition control camraPosition ,default front*/
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/** The beautyFace control capture shader filter empty or beautiy */
@property (nonatomic, assign) BOOL beautyFace;

/** The beautyLevel control beautyFace Level. Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat beautyLevel;

/** The brightLevel control brightness Level, Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat brightLevel;

/** The torch control camera zoom scale default 1.0, between 1.0 ~ 3.0 */
@property (nonatomic, assign) CGFloat zoomScale;

/** The torch control capture flash is on or off */
@property (nonatomic, assign) BOOL torch;

/** The mirror control mirror of front camera is on or off */
@property (nonatomic, assign) BOOL mirror;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/*  The adaptiveBitrate control auto adjust bitrate. Default is NO */
@property (nonatomic, assign) BOOL adaptiveBitrate;

/** The stream control upload and package*/
@property (nullable, nonatomic, strong, readonly) LiveStreamInfo *streamInfo;

/** The status of the stream .*/
@property (nonatomic, assign, readonly) LiveState state;

/** The captureType control inner or outer audio and video .*/
@property (nonatomic, assign, readonly) LiveCaptureTypeMask captureType;

/** The showDebugInfo control streamInfo and uploadInfo(1s) *.*/
@property (nonatomic, assign) BOOL showDebugInfo;

/** The reconnectInterval control reconnect timeInterval(重连间隔) *.*/
@property (nonatomic, assign) NSUInteger reconnectInterval;

/** The reconnectCount control reconnect count (重连次数) *.*/
@property (nonatomic, assign) NSUInteger reconnectCount;

/*** The warterMarkView control whether the watermark is displayed or not ,if set ni,will remove watermark,otherwise add. 
 set alpha represent mix.Position relative to outVideoSize.
 *.*/
//@property (nonatomic, strong, nullable) UIView *warterMarkView;

/* The currentImage is videoCapture shot */
@property (nonatomic, strong,readonly ,nullable) UIImage *currentImage;

/* The saveLocalVideo is save the local video */
@property (nonatomic, assign) BOOL saveLocalVideo;

/* The saveLocalVideoPath is save the local video  path */
@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
   The designated initializer. Multiple instances with the same configuration will make the
   capture unstable.
 */
- (nullable instancetype)initWithAudioConfiguration:(nullable LiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable LiveVideoConfiguration *)videoConfiguration;

/**
 The designated initializer. Multiple instances with the same configuration will make the
 capture unstable.
 */
- (nullable instancetype)initWithAudioConfiguration:(nullable LiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable LiveVideoConfiguration *)videoConfiguration captureType:(LiveCaptureTypeMask)captureType NS_DESIGNATED_INITIALIZER;

/** The start stream .*/
- (void)startLive:(nonnull LiveStreamInfo *)streamInfo;

/** The stop stream .*/
- (void)stopLive;

/** support outer input yuv or rgb video(set LiveCaptureTypeMask) .*/
- (void)pushVideo:(nullable CVPixelBufferRef)pixelBuffer;

/** support outer input pcm audio(set LiveCaptureTypeMask) .*/
- (void)pushAudio:(nullable NSData*)audioData;

@end

