//
//  ViewController.swift
//  LiveKitSwiftDemo
//

import UIKit
import LiveKit

class ViewController: UIViewController {
    
    var cameraPosition: AVCaptureDevice.Position = .back

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //session.delegate = self
        session.previewImageView = view
        
        self.requestAccessForVideo()
        self.requestAccessForAudio()
        self.view.backgroundColor = UIColor.clear
        
        self.view.addSubview(containerView)
        containerView.addSubview(stateLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(cameraButton)
        containerView.addSubview(startLiveButton)
    
        cameraButton.addTarget(self, action: #selector(didTappedCameraButton(_:)), for:.touchUpInside)
        startLiveButton.addTarget(self, action: #selector(didTappedStartLiveButton(_:)), for: .touchUpInside)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
//        coordinator.animate(alongsideTransition: { _ -> Void in
//            self.videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
//            self.videoPreviewLayer?.frame.size = size
//        }, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: AccessAuth
    
    func requestAccessForVideo() -> Void {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video);
        switch status  {
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if(granted){
                    DispatchQueue.main.async { [weak self] in
                        self?.session.beginRunning()
                    }
                }
            })
            break;
        case AVAuthorizationStatus.authorized:
            session.beginRunning()
            break;
        case AVAuthorizationStatus.denied: break
        case AVAuthorizationStatus.restricted:break;
        default:
            break;
        }
    }
    
    func requestAccessForAudio() -> Void {
        let status = AVCaptureDevice.authorizationStatus(for:AVMediaType.audio)
        switch status  {
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (granted) in
                
            })
            break;
        case AVAuthorizationStatus.authorized:
            break;
        case AVAuthorizationStatus.denied: break
        case AVAuthorizationStatus.restricted:break;
        default:
            break;
        }
    }

    //MARK: - Events

    @objc func didTappedStartLiveButton(_ button: UIButton) -> Void {
        startLiveButton.isSelected = !startLiveButton.isSelected;
        if (startLiveButton.isSelected) {
            startLiveButton.setTitle("START", for: UIControl.State())
//            let stream = LiveStreamInfo()
//            stream.url = "rtmp://live.hkstv.hk.lxdns.com:1935/live/stream153"
//            session.startLive(stream)
            let stream = LiveStreamInfo()
            stream.url = "rtmp://18.211.251.191:1935/live/primary"
            session.startLive(with: stream)
        } else {
            startLiveButton.setTitle("STOP", for: UIControl.State())
            session.stopLive()
        }
    }

    @objc func didTappedCameraButton(_ button: UIButton) -> Void {
        let currentPosition = cameraPosition
        cameraPosition = currentPosition == .back ? .front : .back
        session.toggleDevicePosition(to: cameraPosition)
    }

    func didTappedCloseButton(_ button: UIButton) -> Void  {
        
    }

    //MARK: - Getters and Setters

    var session: LiveSession = {
        let audioConfiguration = LiveAudioConfiguration.defaultConfiguration(for: LiveAudioQuality.high)!
        let videoConfiguration = LiveVideoConfiguration.defaultConfiguration(for: LiveVideoQuality.low3)!
        let session = LiveSession(with: audioConfiguration, videoConfiguration: videoConfiguration)
        return session
    }()

    var containerView: UIView = {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        containerView.backgroundColor = UIColor.clear
        containerView.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleHeight]
        return containerView
    }()

    var stateLabel: UILabel = {
        let stateLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 80, height: 40))
        stateLabel.text = "State"
        stateLabel.textColor = UIColor.white
        stateLabel.font = UIFont.systemFont(ofSize: 14)
        return stateLabel
    }()

    var closeButton: UIButton = {
        let closeButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 10 - 44, y: 20, width: 44, height: 44))
        closeButton.setImage(UIImage(named: "close_preview"), for: UIControl.State())
        return closeButton
    }()

    var cameraButton: UIButton = {
        let cameraButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 54 * 2, y: 20, width: 44, height: 44))
        cameraButton.setImage(UIImage(named: "camra_preview"), for: UIControl.State())
        return cameraButton
    }()

    var startLiveButton: UIButton = {
        let startLiveButton = UIButton(frame: CGRect(x: 30, y: UIScreen.main.bounds.height - 50, width: UIScreen.main.bounds.width - 10 - 44, height: 44))
        startLiveButton.layer.cornerRadius = 22
        startLiveButton.setTitleColor(UIColor.black, for:UIControl.State())
        startLiveButton.setTitle("START", for: UIControl.State())
        startLiveButton.titleLabel!.font = UIFont.systemFont(ofSize: 14)
        return startLiveButton
    }()
}

extension ViewController: LiveSessionDelegate {
    func stateChange(to state: LiveState) {
        print("liveStateDidChange: \(state.rawValue)")
        switch state {
        case LiveState.ready:
            stateLabel.text = "Ready"
            break;
        case LiveState.pending:
            stateLabel.text = "Pending"
            break;
        case LiveState.broadcasting:
            stateLabel.text = "Start"       
            break;
        case LiveState.error:
            stateLabel.text = "Error"
            break;
        case LiveState.ended:
            stateLabel.text = "Stop"
            break;
        default:
            break;
        }
    }
    
    func liveDebugInfo(info: LiveDebug) {
        
    }
    
    func didError(with code: LiveSocketErrorCode) {
        print("errorCode: \(code.rawValue)")
    }

    func liveSession(_ session: LiveSession?, debugInfo: LiveDebug?) {
        print("debugInfo: \(String(describing: debugInfo?.currentBandwidth))")
    }

}

