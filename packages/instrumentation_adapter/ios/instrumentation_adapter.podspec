#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'instrumentation_adapter'
  s.version          = '0.0.1'
  s.summary          = 'Instrumentation adapter.'
  s.description      = <<-DESC
Runs tests that use the flutter_test API as integration tests.
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/master/packages/instrumentation_adapter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
end

