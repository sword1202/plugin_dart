#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'firebase_remote_config'
  s.version          = '0.0.1'
  s.summary          = 'Firebase Remote Config plugin for Flutter'
  s.description      = <<-DESC
Firebase Remote Config plugin for Flutter.
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/master/packages/firebase_remote_config'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.ios.deployment_target = '6.0'
  s.dependency 'Flutter'
  s.dependency 'Firebase/RemoteConfig'
  s.static_framework = true
end

