Pod::Spec.new do |s|
  s.name             = 'pixel_to_pdf'
  s.version          = '1.0.5'
  s.summary          = 'A comprehensive attachment picker and document scanner.'
  s.description      = <<-DESC
A comprehensive attachment picker and document scanner for Flutter. Supports camera, gallery, file picking, and native document scanning with cropping.
                       DESC
  s.homepage         = 'https://github.com/ChaniduMadalagama/pixel_to_pdf'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
