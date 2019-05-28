
Pod::Spec.new do |s|

  s.name         = "LiveKit"
  s.version      = "0.1"
  s.summary      = "iOS Live. LiveKit."
  s.homepage     = "https://github.com/washingtonpost/ios-livekit"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "The Washington Post" => "iosdevpluscontractors@washpost.com" }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '11.0'

  s.source       = { :git => "https://github.com/washingtonpost/ios-livekit.git", :tag => "#{s.version}" }
  s.source_files  = "LiveKit/**/*"
  s.public_header_files = ['LiveKit/*.h', 'LiveKit/public/*.h']

  s.preserve_paths = "LiveKit.framework/*"
  s.resources = "LiveKit.framework/*.metallib"

  # s.dependency 'EVGPUImage2' (GPUImage2 - swift )

  s.frameworks = "VideoToolbox", "AudioToolbox","AVFoundation","Foundation","UIKit", "Metal", "CoreGraphics"
  s.libraries = "c++", "z"
  s.swift_version = '5.0'

  s.requires_arc = true
end
