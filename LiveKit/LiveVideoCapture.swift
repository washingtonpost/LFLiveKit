//
//  VideoCapture.swift
//  LiveKit
//
//  Created by Davis, Tyler on 5/20/19.
//  Copyright © 2019. All rights reserved.
//

import AVKit
import Foundation

@objc public protocol VideoCaptureDelegate {
    func captureOutput(capture: LiveVideoCapture?, pixelBuffer: CVPixelBuffer?)
}

@objc public class LiveVideoCapture: NSObject {

    @objc public weak var delegate: VideoCaptureDelegate?

    public var running = false

    @objc public var captureDevicePosition: AVCaptureDevice.Position = .back
    
    /// The beautyFace control capture shader filter empty or beauty
    public var beautyFace = false

    /// The torch control capture flash is on or off
    public var torch = false {
        didSet {
            // TODO torch/flash mode
        }
    }

    /// The mirror control mirror of front camera is on or off
    public var mirror = false

    /// The beautyLevel control beautyFace Level, default 0.5, between 0.0 ~ 1.0
    public var beautyLevel: CGFloat = 0.5

    /// The zoom control camera zoom scale default 1.0, between 1.0 ~ 3.0
    public var zoomScale: CGFloat = 1.0

    public var videoFrameRate: Int = 0

    @objc public var currentImage: UIImage?

    public var saveLocalVideo = false

    public var saveLocalVideoPath: URL?

    var videoConfiguration: LiveVideoConfiguration

    var videoCamera: Camera

    lazy var renderView: RenderView? = {
        let view = RenderView(frame: UIScreen.main.bounds)
        return view
    }()

    let filter = SaturationAdjustment()

    lazy var pictureOutput: PictureOutput = {
        let output = PictureOutput()
        output.imageAvailableCallback = { [weak self] image in
            self?.process(image: image)
        }
        return output
    }()

    @objc public var previewImageView: UIView? {
        didSet {
            guard let renderView = renderView else {
                return
            }

            previewImageView?.insertSubview(renderView, at: 0)
            renderView.frame = CGRect(origin: .zero, size: previewImageView?.frame.size ?? .zero)
        }
    }

    @objc public init(with videoConfiguration: LiveVideoConfiguration) {
        self.videoConfiguration = videoConfiguration
        do {
            videoCamera = try Camera(sessionPreset: .high)
        } catch {
            fatalError("Could not initialize rendering pipeline")
        }
        super.init()

        // Test
        videoCamera --> filter --> renderView!
        filter --> pictureOutput
    }

    deinit {
        videoCamera.stopCapture()
        renderView?.removeFromSuperview()
        renderView = nil
    }

    @objc public func begin() {
        guard !running else {
            return
        }

        UIApplication.shared.isIdleTimerDisabled = true
        videoCamera.startCapture()
    }

    @objc public func end() {
        guard running else {
            return
        }

        UIApplication.shared.isIdleTimerDisabled = false
        videoCamera.stopCapture()
    }

    func process(image: UIImage) {
        // TODO
        delegate?.captureOutput(capture: self, pixelBuffer: nil)
    }
}
