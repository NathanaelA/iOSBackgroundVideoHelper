#
# Be sure to run `pod lib lint video-helper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "VideoHelper"
  s.version          = "0.0.1"
  s.summary          = "A simple background thread helper for videos"

  s.description      = <<-DESC
  Allows you to downkload videos in iOS.
                       DESC

  s.homepage         = "https://git.master-technology.com/nativescript/ios-video"
  s.license          = 'Commercial'
  s.author           = { "Nathanael Anderson" => "Nathan@master-technology.com" }
  s.source           = { :git => "https://github.com/nativescript/ios-video.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'

end
