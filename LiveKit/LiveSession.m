//
//  LiveSession.m
//  LiveKit
//
//  Created by LaiFeng on 16/5/20.
//  Copyright © 2016年 LaiFeng All rights reserved.
//

#import "LiveSession.h"
#import "AudioCapture.h"
#import "LFHardwareVideoEncoder.h"
#import "LFHardwareAudioEncoder.h"
#import "LFH264VideoEncoder.h"
#import "StreamRTMPSocket.h"
#import "LiveStreamInfo.h"
//#import "LFGPUImageBeautyFilter.h"
#import "LFH264VideoEncoder.h"

#import <LiveKit/LiveKit-Swift.h>

@interface LiveSession ()<AudioCaptureDelegate, VideoCaptureDelegate, AudioEncodingDelegate, VideoEncodingDelegate, StreamSocketDelegate>

/// 音频配置
@property (nonatomic, strong) LiveAudioConfiguration *audioConfiguration;
/// 视频配置
@property (nonatomic, strong) LiveVideoConfiguration *videoConfiguration;
/// 声音采集
@property (nonatomic, strong) AudioCapture *audioCaptureSource;
/// 视频采集
//@property (nonatomic, strong) VideoCapture *videoCaptureSource;

@property (nonatomic, strong) LiveVideoCapture *videoCaptureSource;

/// 音频编码
@property (nonatomic, strong) id<AudioEncoding> audioEncoder;
/// 视频编码
@property (nonatomic, strong) id<VideoEncoding> videoEncoder;
/// 上传
@property (nonatomic, strong) id<StreamSocket> socket;


#pragma mark -- 内部标识
/// 调试信息
@property (nonatomic, strong) LiveDebug *debugInfo;
/// 流信息
@property (nonatomic, strong) LiveStreamInfo *streamInfo;
/// 是否开始上传
@property (nonatomic, assign) BOOL uploading;
/// 当前状态
@property (nonatomic, assign, readwrite) LiveState state;
/// 当前直播type
@property (nonatomic, assign, readwrite) LiveCaptureTypeMask captureType;
/// 时间戳锁
@property (nonatomic, strong) dispatch_semaphore_t lock;


@end

/**  时间戳 */
#define NOW (CACurrentMediaTime()*1000)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface LiveSession ()

/// 上传相对时间戳
@property (nonatomic, assign) uint64_t relativeTimestamps;
/// 音视频是否对齐
@property (nonatomic, assign) BOOL AVAlignment;
/// 当前是否采集到了音频
@property (nonatomic, assign) BOOL hasCaptureAudio;
/// 当前是否采集到了关键帧
@property (nonatomic, assign) BOOL hasKeyFrameVideo;

@end

@implementation LiveSession

#pragma mark -- LifeCycle
- (instancetype)initWithAudioConfiguration:(nullable LiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable LiveVideoConfiguration *)videoConfiguration {
    return [self initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration captureType:LiveCaptureDefaultMask];
}

- (nullable instancetype)initWithAudioConfiguration:(nullable LiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable LiveVideoConfiguration *)videoConfiguration captureType:(LiveCaptureTypeMask)captureType{
    if((captureType & LiveCaptureMaskAudio || captureType & LiveInputMaskAudio) && !audioConfiguration) @throw [NSException exceptionWithName:@"LiveSession init error" reason:@"audioConfiguration is nil " userInfo:nil];
    if((captureType & LiveCaptureMaskVideo || captureType & LiveInputMaskVideo) && !videoConfiguration) @throw [NSException exceptionWithName:@"LiveSession init error" reason:@"videoConfiguration is nil " userInfo:nil];
    if (self = [super init]) {
        _audioConfiguration = audioConfiguration;
        _videoConfiguration = videoConfiguration;
        _adaptiveBitrate = NO;
        _captureType = captureType;
    }
    return self;
}

- (void)dealloc {
    [_videoCaptureSource end];
    _audioCaptureSource.running = NO;
}

#pragma mark -- CustomMethod
- (void)startLive:(LiveStreamInfo *)streamInfo {
    if (!streamInfo) return;
    _streamInfo = streamInfo;
    _streamInfo.videoConfiguration = _videoConfiguration;
    _streamInfo.audioConfiguration = _audioConfiguration;
    [self.socket start];
}

- (void)stopLive {
    self.uploading = NO;
    [self.socket stop];
    self.socket = nil;
}

- (void)pushVideo:(nullable CVPixelBufferRef)pixelBuffer{
    if(self.captureType & LiveInputMaskVideo){
        if (self.uploading) [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:NOW];
    }
}

- (void)pushAudio:(nullable NSData*)audioData{
    if(self.captureType & LiveInputMaskAudio){
        if (self.uploading) [self.audioEncoder encodeAudioData:audioData timeStamp:NOW];
    }
}

#pragma mark -- PrivateMethod
- (void)pushSendBuffer:(LFFrame*)frame{
    if(self.relativeTimestamps == 0){
        self.relativeTimestamps = frame.timestamp;
    }
    frame.timestamp = [self uploadTimestamp:frame.timestamp];
    [self.socket sendFrame:frame];
}

#pragma mark -- CaptureDelegate
- (void)captureOutput:(nullable AudioCapture *)capture audioData:(nullable NSData*)audioData {
    if (self.uploading) [self.audioEncoder encodeAudioData:audioData timeStamp:NOW];
}

- (void)captureOutputWithCapture:(LiveVideoCapture * _Nullable)capture pixelBuffer:(CVPixelBufferRef _Nullable)pixelBuffer {
    if (self.uploading) [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:NOW];
}

#pragma mark -- EncoderDelegate
- (void)audioEncoder:(nullable id<AudioEncoding>)encoder audioFrame:(nullable AudioFrame *)frame {
    if (self.uploading){
        self.hasCaptureAudio = YES;
        if(self.AVAlignment) [self pushSendBuffer:frame];
    }
}

- (void)videoEncoder:(nullable id<VideoEncoding>)encoder videoFrame:(nullable VideoFrame *)frame {
    if (self.uploading){
        if(frame.isKeyFrame && self.hasCaptureAudio) self.hasKeyFrameVideo = YES;
        if(self.AVAlignment) [self pushSendBuffer:frame];
    }
}

#pragma mark -- StreamTcpSocketDelegate
- (void)socketStatus:(nullable id<StreamSocket>)socket status:(LiveState)status {
    if (status == LiveStart) {
        if (!self.uploading) {
            self.AVAlignment = NO;
            self.hasCaptureAudio = NO;
            self.hasKeyFrameVideo = NO;
            self.relativeTimestamps = 0;
            self.uploading = YES;
        }
    } else if(status == LiveStop || status == LiveError){
        self.uploading = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = status;
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:liveStateDidChange:)]) {
            [self.delegate liveSession:self liveStateDidChange:status];
        }
    });
}

- (void)socketDidError:(nullable id<StreamSocket>)socket errorCode:(LiveSocketErrorCode)errorCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:errorCode:)]) {
            [self.delegate liveSession:self errorCode:errorCode];
        }
    });
}

- (void)socketDebug:(nullable id<StreamSocket>)socket debugInfo:(nullable LiveDebug *)debugInfo {
    self.debugInfo = debugInfo;
    if (self.showDebugInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(liveSession:debugInfo:)]) {
                [self.delegate liveSession:self debugInfo:debugInfo];
            }
        });
    }
}

- (void)socketBufferStatus:(nullable id<StreamSocket>)socket status:(LiveBuffferState)status {
    if((self.captureType & LiveCaptureMaskVideo || self.captureType & LiveInputMaskVideo) && self.adaptiveBitrate){
        NSUInteger videoBitRate = [self.videoEncoder videoBitRate];
        if (status == LiveBuffferDecline) {
            if (videoBitRate < _videoConfiguration.videoMaxBitRate) {
                videoBitRate = videoBitRate + 50 * 1000;
                [self.videoEncoder setVideoBitRate:videoBitRate];
                NSLog(@"Increase bitrate %@", @(videoBitRate));
            }
        } else {
            if (videoBitRate > self.videoConfiguration.videoMinBitRate) {
                videoBitRate = videoBitRate - 100 * 1000;
                [self.videoEncoder setVideoBitRate:videoBitRate];
                NSLog(@"Decline bitrate %@", @(videoBitRate));
            }
        }
    }
}

#pragma mark -- Getter Setter
- (void)setRunning:(BOOL)running {
    if (_running == running) return;
    [self willChangeValueForKey:@"running"];
    _running = running;
    [self didChangeValueForKey:@"running"];
    [self.videoCaptureSource begin];
    self.audioCaptureSource.running = _running;
}

- (void)setPreviewImageView:(UIView *)previewImageView {
    [self willChangeValueForKey:@"previewImageView"];
    [self.videoCaptureSource setPreviewImageView:previewImageView];
    [self didChangeValueForKey:@"previewImageView"];
}

- (UIView *)previewImageView {
    return self.videoCaptureSource.previewImageView;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition {
    [self willChangeValueForKey:@"captureDevicePosition"];
    [self.videoCaptureSource setCaptureDevicePosition:captureDevicePosition];
    [self didChangeValueForKey:@"captureDevicePosition"];
}

- (AVCaptureDevicePosition)captureDevicePosition {
    return self.videoCaptureSource.captureDevicePosition;
}

- (void)setBeautyFace:(BOOL)beautyFace {
    [self willChangeValueForKey:@"beautyFace"];
    [self.videoCaptureSource setBeautyFace:beautyFace];
    [self didChangeValueForKey:@"beautyFace"];
}

- (BOOL)saveLocalVideo{
    return self.videoCaptureSource.saveLocalVideo;
}

- (void)setSaveLocalVideo:(BOOL)saveLocalVideo{
    [self.videoCaptureSource setSaveLocalVideo:saveLocalVideo];
}


- (NSURL*)saveLocalVideoPath{
    return self.videoCaptureSource.saveLocalVideoPath;
}

- (void)setSaveLocalVideoPath:(NSURL*)saveLocalVideoPath{
   [self.videoCaptureSource setSaveLocalVideoPath:saveLocalVideoPath];
}

- (BOOL)beautyFace {
    return self.videoCaptureSource.beautyFace;
}

- (void)setBeautyLevel:(CGFloat)beautyLevel {
    [self willChangeValueForKey:@"beautyLevel"];
    [self.videoCaptureSource setBeautyLevel:beautyLevel];
    [self didChangeValueForKey:@"beautyLevel"];
}

- (CGFloat)beautyLevel {
    return self.videoCaptureSource.beautyLevel;
}

- (void)setBrightLevel:(CGFloat)brightLevel {
    [self willChangeValueForKey:@"brightLevel"];
    [self.videoCaptureSource setBrightLevel:brightLevel];
    [self didChangeValueForKey:@"brightLevel"];
}

- (CGFloat)brightLevel {
    return self.videoCaptureSource.brightLevel;
}

- (void)setZoomScale:(CGFloat)zoomScale {
    [self willChangeValueForKey:@"zoomScale"];
    [self.videoCaptureSource setZoomScale:zoomScale];
    [self didChangeValueForKey:@"zoomScale"];
}

- (CGFloat)zoomScale {
    return self.videoCaptureSource.zoomScale;
}

- (void)setTorch:(BOOL)torch {
    [self willChangeValueForKey:@"torch"];
    [self.videoCaptureSource setTorch:torch];
    [self didChangeValueForKey:@"torch"];
}

- (BOOL)torch {
    return self.videoCaptureSource.torch;
}

- (void)setMirror:(BOOL)mirror {
    [self willChangeValueForKey:@"mirror"];
    [self.videoCaptureSource setMirror:mirror];
    [self didChangeValueForKey:@"mirror"];
}

- (BOOL)mirror {
    return self.videoCaptureSource.mirror;
}

- (void)setMuted:(BOOL)muted {
    [self willChangeValueForKey:@"muted"];
    [self.audioCaptureSource setMuted:muted];
    [self didChangeValueForKey:@"muted"];
}

- (BOOL)muted {
    return self.audioCaptureSource.muted;
}

- (nullable UIImage *)currentImage{
    return self.videoCaptureSource.currentImage;
}

- (AudioCapture *)audioCaptureSource {
    if (!_audioCaptureSource) {
        if(self.captureType & LiveCaptureMaskAudio){
            _audioCaptureSource = [[AudioCapture alloc] initWithAudioConfiguration:_audioConfiguration];
            _audioCaptureSource.delegate = self;
        }
    }
    return _audioCaptureSource;
}

- (LiveVideoCapture *)videoCaptureSource {
    if (!_videoCaptureSource) {
        if(self.captureType & LiveCaptureMaskVideo){
            _videoCaptureSource = [[LiveVideoCapture alloc] initWith:_videoConfiguration];
            _videoCaptureSource.delegate = self;
        }
    }
    return _videoCaptureSource;
}

- (id<AudioEncoding>)audioEncoder {
    if (!_audioEncoder) {
        _audioEncoder = [[LFHardwareAudioEncoder alloc] initWithAudioStreamConfiguration:_audioConfiguration];
        [_audioEncoder setDelegate:self];
    }
    return _audioEncoder;
}

- (id<VideoEncoding>)videoEncoder {
    if (!_videoEncoder) {
        if([[UIDevice currentDevice].systemVersion floatValue] < 8.0){
            _videoEncoder = [[LFH264VideoEncoder alloc] initWithVideoStreamConfiguration:_videoConfiguration];
        }else{
            _videoEncoder = [[LFHardwareVideoEncoder alloc] initWithVideoStreamConfiguration:_videoConfiguration];
        }
        [_videoEncoder setDelegate:self];
    }
    return _videoEncoder;
}

- (id<StreamSocket>)socket {
    if (!_socket) {
        _socket = [[StreamRTMPSocket alloc] initWithStream:self.streamInfo reconnectInterval:self.reconnectInterval reconnectCount:self.reconnectCount];
        [_socket setDelegate:self];
    }
    return _socket;
}

- (LiveStreamInfo *)streamInfo {
    if (!_streamInfo) {
        _streamInfo = [[LiveStreamInfo alloc] init];
    }
    return _streamInfo;
}

- (dispatch_semaphore_t)lock{
    if(!_lock){
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

- (uint64_t)uploadTimestamp:(uint64_t)captureTimestamp{
    dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    currentts = captureTimestamp - self.relativeTimestamps;
    dispatch_semaphore_signal(self.lock);
    return currentts;
}

- (BOOL)AVAlignment{
    if((self.captureType & LiveCaptureMaskAudio || self.captureType & LiveInputMaskAudio) &&
       (self.captureType & LiveCaptureMaskVideo || self.captureType & LiveInputMaskVideo)
       ){
        if(self.hasCaptureAudio && self.hasKeyFrameVideo) return YES;
        else  return NO;
    }else{
        return YES;
    }
}

@end
