Pod::Spec.new do |s|
  s.name         = "AHAlertView"
  s.version      = "1.0.0"
  s.summary      = "`AHAlertView` is a powerful, block-based alternative to UIKit's `UIAlertView`. "
  s.homepage     = "https://github.com/warrenm/AHAlertView.git"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Warren Moore" => "wm@warrenmoore.net" }
  s.source       = { :git => "https://github.com/warrenm/AHAlertView.git", :tag => "1.0.0" }
  s.platform     = :ios, '5.0'
  s.source_files = 'Class', 'AHAlertView/**/*.{h,m}'
  s.public_header_files = 'AHAlertView/**/*.h'
  s.frameworks  = 'QuartzCore'
  s.requires_arc = true
end
