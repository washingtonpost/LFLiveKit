//
//  VideoCapture.swift
//  LiveKit
//
//  Created by Davis, Tyler on 5/20/19.
//  Copyright © 2019. All rights reserved.
//

import AVKit
import Foundation
import UIKit

@objc public protocol VideoCaptureDelegate {
    func captureOutput(capture: LiveVideoCapture?, pixelBuffer: CVPixelBuffer?)
}

@objc public class LiveVideoCapture: NSObject {

    @objc public weak var delegate: VideoCaptureDelegate?

    @objc public var captureDevicePosition: AVCaptureDevice.Position = .back {
        didSet {
            videoCamera.location = captureDevicePosition == .back ? .backFacing : .frontFacing
        }
    }
    
    /// The torch control capture flash is on or off
    @objc  public var torch = false {
        didSet {
            videoCamera.toggleTorch(on: torch)
        }
    }

    /* TODO: These need cooresponding filter and/or adjustments to work */
    /// The beautyFace control capture shader filter empty or beauty
    @objc public var beautyFace = false
    /// The mirror control mirror of front camera is on or off
    @objc public var mirror = false
    /// The beautyLevel control beautyFace Level, default 0.5, between 0.0 ~ 1.0
    @objc public var beautyLevel: CGFloat = 0.5
    /// The brightLevel control brightness Level, default 0.5, between 0.0 ~ 1.0
    @objc public var brightLevel: CGFloat = 0.5
    /// The zoom control camera zoom scale default 1.0, between 1.0 ~ 3.0
    @objc public var zoomScale: CGFloat = 1.0 {
        didSet {
            videoCamera.videoZoomScale = zoomScale
        }
    }
    
    @objc public var videoFrameRate: Int = 0

    @objc public var currentImage: UIImage?

    @objc public var saveLocalVideo = false

    @objc public var saveLocalVideoPath: URL?

    let videoConfiguration: LiveVideoConfiguration

    var videoCamera: Camera

    lazy var renderView: RenderView? = {
        let view = RenderView(frame: UIScreen.main.bounds)
        return view
    }()

    // TODO: More filters?
    let filter = SaturationAdjustment()

    /// Images to RTMP
    lazy var pictureOutput: PictureOutput = {
        let output = PictureOutput()
        output.onlyCaptureNextFrame = false
        output.imageAvailableCallback = { [weak self] image in
            self?.process(image: image)
        }
        return output
    }()

    @objc public var previewImageView: UIView? {
        get {
            return self.renderView!.superview!
        }
        set {
            guard let renderView = renderView else {
                return
            }
            if renderView.superview != nil {
                renderView.removeFromSuperview()
            }
            newValue?.insertSubview(renderView, at: 0)
            renderView.fitInSuperviewWithConstraints()
        }
    }

    @objc public init(with videoConfiguration: LiveVideoConfiguration) {
        self.videoConfiguration = videoConfiguration
        do {
            videoCamera = try Camera(sessionPreset: .high)
        } catch {
            print("Could not initialize rendering pipeline. \(error)")
            fatalError("Could not initialize rendering pipeline. \(error)")
        }

        super.init()

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            self?.end()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) {
            [weak self] _ in
            self?.begin()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(statusBarChanged), name: UIApplication.willChangeStatusBarFrameNotification, object: nil)
    }

    deinit {
        videoCamera.stopCapture()
        renderView?.removeFromSuperview()
        renderView = nil
    }

    @objc public func begin() {
        guard let renderView = self.renderView else {
            return
        }
        // Test
        videoCamera --> filter --> renderView
        filter --> pictureOutput

        switchIdleTimer(to: true)
        videoCamera.startCapture()
    }

    @objc public func end() {
        switchIdleTimer(to: false)
        videoCamera.stopCapture()
    }

    func process(image: UIImage) {
        delegate?.captureOutput(capture: self, pixelBuffer: buffer(from: image))
    }

    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }

    func switchIdleTimer(to enabled: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = enabled
        }
    }

    @objc func statusBarChanged(notification: Notification) {
        if videoConfiguration.autorotate {
            videoCamera.changeOrientation()
        }
    }

}

public extension UIView {

    /// Fits view within a superview using entire superview bounds.
    func fitInSuperviewWithConstraints() {
        guard let superview = superview else {
            return
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        let views = ["self": self]
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[self]|", options: [], metrics: nil, views: views))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[self]|", options: [], metrics: nil, views: views))
    }
    
}

