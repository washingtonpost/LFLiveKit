LiveKit
==============

**LiveKit is a opensource RTMP streaming SDK for iOS forked from LiveKit and maintained by WashPost.**  

## Features

- [x] 	Background recording
- [x] 	Support horizontal vertical recording
- [x] 	Support Beauty Face With GPUImage
- [x] 	Support H264+AAC Hardware Encoding
- [x] 	Drop frames on bad network 
- [x] 	Dynamic switching rate
- [x] 	Audio configuration
- [x] 	Video configuration
- [x] 	RTMP Transport
- [x] 	Switch camera position
- [x] 	Audio Mute
- [x] 	Support Send Buffer
- [x] 	Support WaterMark
- [x] 	Swift Support
- [x] 	Support Single Video or Audio 
- [x] 	Support External input video or audio(Screen recording or Peripheral)
- [ ] 	~~FLV package and send~~

## Requirements
    - iOS 10.0+
    - Xcode 10.2
  
## Installation

#### CocoaPods
	# To integrate LiveKit into your Xcode project using CocoaPods, specify it in your Podfile:

	source 'https://github.com/CocoaPods/Specs.git'
	platform :ios, '10.0'
	pod 'LiveKit'
	
	# Then, run the following command:
	$ pod install


#### Manually

    1. Download all the files in the `LiveKit` subdirectory.
    2. Add the source files to your Xcode project.
    3. Link with required frameworks:
        * UIKit
        * Foundation
        * AVFoundation
        * VideoToolbox
        * AudioToolbox
        * libz
        * libstdc++
	
## Usage example 

#### Objective-C
```objc
- (LiveSession*)session {
	if (!_session) {
	    _session = [[LiveSession alloc] initWithAudioConfiguration:[LiveAudioConfiguration defaultConfiguration] videoConfiguration:[LiveVideoConfiguration defaultConfiguration]];
	    _session.preView = self;
	    _session.delegate = self;
	}
	return _session;
}

- (void)startLive {	
	LiveStreamInfo *streamInfo = [LiveStreamInfo new];
	streamInfo.url = @"your server rtmp url";
	[self.session startLive:streamInfo];
}

- (void)stopLive {
	[self.session stopLive];
}

//MARK: - CallBack:
- (void)liveSession:(nullable LiveSession *)session liveStateDidChange: (LiveState)state;
- (void)liveSession:(nullable LiveSession *)session debugInfo:(nullable LiveDebug*)debugInfo;
- (void)liveSession:(nullable LiveSession*)session errorCode:(LiveSocketErrorCode)errorCode;
```
#### Swift
TODO update
```swift
import LiveKit

//MARK: - Getters and Setters
lazy var session: LiveSession = {
	let audioConfiguration = LiveAudioConfiguration.defaultConfiguration()
	let videoConfiguration = LiveVideoConfiguration.defaultConfigurationForQuality(LiveVideoQuality.Low3, landscape: false)
	let session = LiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)
	    
	session?.delegate = self
	session?.preView = self.view
	return session!
}()

//MARK: - Event
func startLive() -> Void { 
	let stream = LiveStreamInfo()
	stream.url = "your server rtmp url";
	session.startLive(stream)
}

func stopLive() -> Void {
	session.stopLive()
}

//MARK: - Callback
func liveSession(session: LiveSession?, debugInfo: LiveDebug?) 
func liveSession(session: LiveSession?, errorCode: LiveSocketErrorCode)
func liveSession(session: LiveSession?, liveStateDidChange state: LiveState)
```

## Release History
   TODO.


## License
 **LiveKit is released under the MIT license. See LICENSE for details.**




