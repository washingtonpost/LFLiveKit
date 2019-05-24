//
//  LiveSession.swift
//  LiveKit
//
//  Created by Davis, Tyler on 5/20/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit

public enum LiveCaptureType: Int {
    case captureAudio
    case captureVideo
    case inputAudio
    case inputVideo
}

public struct LiveCaptureTypeMask: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let captureAudio = LiveCaptureTypeMask(rawValue: 1 << LiveCaptureType.captureAudio.rawValue)
    public static let captureVideo = LiveCaptureTypeMask(rawValue: 1 << LiveCaptureType.captureVideo.rawValue)
    public static let inputAudio   = LiveCaptureTypeMask(rawValue: 1 << LiveCaptureType.inputAudio.rawValue)
    public static let inputVideo   = LiveCaptureTypeMask(rawValue: 1 << LiveCaptureType.inputVideo.rawValue)

    public static let captureAll: LiveCaptureTypeMask = [.captureAudio, .captureVideo]
    public static let inputAll: LiveCaptureTypeMask = [.inputAudio, .inputVideo]

    /// inner capture audio and outer input video (method pushVideo and setRunning)
    public static let audioInputVideo: LiveCaptureTypeMask = [.captureAudio, .inputVideo]
    /// inner capture video and outer input audio (method pushAudio and setRunning)
    public static let videoInputAudio: LiveCaptureTypeMask = [.captureVideo, .inputAudio]
}

public protocol LiveSessionDelegate: class {
    func stateChange(to state: LiveState)
    func liveDebugInfo(info: LiveDebug)
    func didError(with code: LiveSocketErrorCode)
}

public class LiveSession: NSObject {

    public weak var delegate: LiveSessionDelegate?

    /// View required for video display.
    public var previewImageView: UIView? {
        didSet {
            videoCaptureSource.previewImageView = previewImageView
        }
    }

    var isRunning = false
    var isUploading = false

    let audioConfiguration: LiveAudioConfiguration
    let videoConfiguration: LiveVideoConfiguration

    /// The stream control upload and package
    var streamInfo: LiveStreamInfo?

    /// The status of the stream
    var state: LiveState = .ready

    /// The captureType control inner or outer audio and video.
    let captureType: LiveCaptureTypeMask

    /// The reconnectInterval control reconnect timeInterval.
    var reconnectInterval: Int = 5

    /// The reconnectCount control reconnect count.
    var reconnectCount = 0

    /// The currentImage is videoCapture shot.
    var currentImage: UIImage? {
        return videoCaptureSource.currentImage
    }

    var lock = DispatchSemaphore(value: 1)
    // TODO?
    var relativeTimestamp: UInt64 = 0
    var AVAlignment = true
    var hasCaptureAudio = true
    var hasKeyFrameVideo = true

    lazy var socket: StreamRTMPSocket? = {
        let rtmpSocket = StreamRTMPSocket(stream: streamInfo, reconnectInterval: reconnectInterval, reconnectCount: reconnectCount)
        rtmpSocket?.setDelegate(self)
        return rtmpSocket
    }()
    
    lazy var videoCaptureSource: LiveVideoCapture = {
        let videoSource = LiveVideoCapture(with: videoConfiguration)
        videoSource.delegate = self
        return videoSource
    }()

    lazy var audioCaptureSource: AudioCapture? = {
        let audioSource = AudioCapture(audioConfiguration: audioConfiguration)
        audioSource?.delegate = self
        return audioSource
    }()

    lazy var videoEncoder: LFHardwareVideoEncoder? = {
        let encoder = LFHardwareVideoEncoder(videoStreamConfiguration: videoConfiguration)
        encoder?.setDelegate(self)
        return encoder
    }()

    lazy var audioEncoder: LFHardwareAudioEncoder? = {
        let encoder = LFHardwareAudioEncoder(audioStreamConfiguration: audioConfiguration)
        encoder?.setDelegate(self)
        return encoder
    }()
    
    public init(with audioConfiguration: LiveAudioConfiguration, videoConfiguration: LiveVideoConfiguration, captureType: LiveCaptureTypeMask = LiveCaptureTypeMask.captureAll) {
        self.audioConfiguration = audioConfiguration
        self.videoConfiguration = videoConfiguration
        self.captureType = captureType
    }

    deinit {
        videoCaptureSource.end()
    }
    
    public func beginRunning() {
        guard !isRunning else {
            return
        }
        // run
        videoCaptureSource.begin()
        audioCaptureSource?.running = true
        isRunning = true
    }

    public func endRunning() {
        // end
        videoCaptureSource.end()
        audioCaptureSource?.running = false
        isRunning = false
    }

    public func startLive(with streamInfo: LiveStreamInfo) {
        self.streamInfo = streamInfo
        streamInfo.videoConfiguration = videoConfiguration
        streamInfo.audioConfiguration = audioConfiguration
        socket?.start()
    }

    public func stopLive() {
        isUploading = false
        socket?.stop()
        socket = nil
    }

    /// Support outer input yuv or rgb video(set LiveCaptureTypeMask)
    func pushVideo(pixelBuffer: CVPixelBuffer?) {
//        if(self.captureType & LiveInputMaskVideo){
//            if (self.uploading) [self.videoEncoder encodeVideoData:pixelBuffer timeStamp:NOW];
//        }
        if isUploading {
            videoEncoder?.encodeVideoData(pixelBuffer, timeStamp: UInt64(CACurrentMediaTime()*1000))
        }
    }

    /// Support outer input pcm audio(set LiveCaptureTypeMask)
    func pushAudio(audioData: Data?) {
//        if(self.captureType & LiveInputMaskAudio){
//            if (self.uploading) [self.audioEncoder encodeAudioData:audioData timeStamp:NOW];
//        }
        if isUploading {
            audioEncoder?.encodeAudioData(audioData, timeStamp: UInt64(CACurrentMediaTime()*1000))
        }
    }

    public func setZoomScale(to zoom: CGFloat) {
        videoCaptureSource.zoomScale = zoom
    }

    public func toggleTorch() {
        let isOn = videoCaptureSource.torch
        videoCaptureSource.torch = !isOn
    }

    public func toggleDevicePosition(to position: AVCaptureDevice.Position) {
        videoCaptureSource.captureDevicePosition = position
    }

    public func muteAudio(_ mute: Bool) {
        audioCaptureSource?.muted = mute
    }
}

extension LiveSession {

    func uploadTimestamp(_ captureTimestamp: UInt64) -> UInt64 {
        let current: UInt64
        lock.wait()
        current = captureTimestamp - relativeTimestamp
        lock.signal()
        return current
    }
    
    func pushSendBuffer(_ frame: LFFrame) {
        if relativeTimestamp == 0 {
            relativeTimestamp = frame.timestamp
        }
        frame.timestamp = uploadTimestamp(frame.timestamp)
        socket?.send(frame)
    }
    
}

extension LiveSession: VideoCaptureDelegate {
    public func captureOutput(capture: LiveVideoCapture?, pixelBuffer: CVPixelBuffer?) {
        if isUploading {
            videoEncoder?.encodeVideoData(pixelBuffer, timeStamp: UInt64(CACurrentMediaTime()*1000))
        }
    }
}

extension LiveSession: AudioCaptureDelegate {
    public func captureOutput(_ capture: AudioCapture?, audioData: Data?) {
        if isUploading {
            audioEncoder?.encodeAudioData(audioData, timeStamp: UInt64(CACurrentMediaTime()*1000))
        }
    }
}

extension LiveSession: VideoEncodingDelegate {
    public func videoEncoder(_ encoder: VideoEncoding?, videoFrame frame: VideoFrame?) {
        guard let frame = frame, isUploading else {
            return
        }
        if frame.isKeyFrame && hasCaptureAudio {
            hasKeyFrameVideo = true
        }
        if AVAlignment {
            pushSendBuffer(frame)
        }
    }
}

extension LiveSession: AudioEncodingDelegate {
    public func audioEncoder(_ encoder: AudioEncoding?, audioFrame frame: AudioFrame?) {
        guard let frame = frame, isUploading else {
            return
        }
        hasCaptureAudio = true
        if AVAlignment {
            pushSendBuffer(frame)
        }
    }
}

extension LiveSession: StreamSocketDelegate {

    public func socketBufferStatus(_ socket: StreamSocket?, status: LiveBufferState) {
//        if((self.captureType & LiveCaptureMaskVideo || self.captureType & LiveInputMaskVideo) && self.adaptiveBitrate){
//            NSUInteger videoBitRate = [self.videoEncoder videoBitRate];
//            if (status == LiveBufferDecline) {
//                if (videoBitRate < _videoConfiguration.videoMaxBitRate) {
//                    videoBitRate = videoBitRate + 50 * 1000;
//                    [self.videoEncoder setVideoBitRate:videoBitRate];
//                    NSLog(@"Increase bitrate %@", @(videoBitRate));
//                }
//            } else {
//                if (videoBitRate > self.videoConfiguration.videoMinBitRate) {
//                    videoBitRate = videoBitRate - 100 * 1000;
//                    [self.videoEncoder setVideoBitRate:videoBitRate];
//                    NSLog(@"Decline bitrate %@", @(videoBitRate));
//                }
//            }
//        }
//
    }
    
    public func socketStatus(_ socket: StreamSocket?, status: LiveState) {

        switch status {
        case .start:
            AVAlignment = false
            hasCaptureAudio = false
            hasKeyFrameVideo = false
            relativeTimestamp = 0
            isUploading = true
        case .stop, .error:
            isUploading = false
        default:
            break
        }

        DispatchQueue.main.async { [weak self] in
            self?.state = status
            self?.delegate?.stateChange(to: status)
        }
    }
    
    public func socketDidError(_ socket: StreamSocket?, errorCode: LiveSocketErrorCode) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didError(with: errorCode)
        }
    }

}

// TODO: Add funciontality
///** The mirror control mirror of front camera is on or off */
//@property (nonatomic, assign) BOOL mirror;
//
///** The muted control callbackAudioData,muted will memset 0.*/
//@property (nonatomic, assign) BOOL muted;
//
///*  The adaptiveBitrate control auto adjust bitrate. Default is NO */
//@property (nonatomic, assign) BOOL adaptiveBitrate;
///** The showDebugInfo control streamInfo and uploadInfo(1s) *.*/
//@property (nonatomic, assign) BOOL showDebugInfo;
//
///* The saveLocalVideo is save the local video */
//@property (nonatomic, assign) BOOL saveLocalVideo;
//
///* The saveLocalVideoPath is save the local video  path */
//@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;
//
