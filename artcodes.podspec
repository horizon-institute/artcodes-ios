# see http://guides.cocoapods.org/syntax/podspec.html

Pod::Spec.new do |s|
	s.name             = "artcodes"
	s.version          = "0.1.1"
	s.summary          = "Library for scanning artcodes"
	s.homepage         = "https://github.com/horizon-institute/aestheticodes-ios.git"
	# s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
	s.license          = 'AGPLv3'
	s.author           = { "Kevin Glover" => "ktg@cs.nott.ac.uk" }
	s.source           = { :git => "https://github.com/horizon-institute/aestheticodes-ios.git", :tag => s.version.to_s }
	# s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

	s.platform     = :ios, '7.0'
	s.requires_arc = true

	s.source_files = 'core/src/**/*'
	s.resource_bundles = {
		'aestheticodes-ios' => ['core/res/**/*']
	}

	s.public_header_files = 'core/src/**/*.h'
	s.frameworks = 'UIKit'
	s.dependency 'OpenCV', '2.4.9.1'
	s.dependency 'JSONModel'
end