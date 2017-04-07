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
  Allows you to download videos in iOS in the background.
                       DESC

  s.homepage         = "https://github.com/NathanaelA/iOSBackgroundVideoHelper"
  s.license          = 'MIT'
  s.author           = { "Nathanael Anderson" => "Nathan@master-technology.com" }
  s.source           = { :git => "https://github.com/NathanaelA/iOSBackgroundVideoHelper.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'

end
