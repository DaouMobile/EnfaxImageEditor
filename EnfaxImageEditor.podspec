Pod::Spec.new do |spec|
  spec.name                     = 'EnfaxImageEditor'
  spec.version                  = '1.0.2'
  spec.homepage                 = 'https://github.com/DaouMobile/EnfaxImageEditor'
  spec.authors                  = { 'DAOU TECH' => 'mobiletest@daou.co.kr' }
  spec.source                   = { :git => 'https://github.com/DaouMobile/EnfaxImageEditor.git', :tag => spec.version.to_s }
  spec.summary                  = 'Image editor for Enfax application'
  spec.swift_version            = '5.0'
  spec.ios.deployment_target    = '11.0'
  spec.source_files             = 'Sources/**/*.swift'
  spec.resources                = 'Sources/**/Resource/*'
  spec.framework                = 'UIKit'
  spec.framework                = 'Vision'
  spec.dependency 'Geometry2D'
  spec.dependency 'RxSwift'
  spec.dependency 'RxRelay'
  spec.dependency 'RxCocoa'
  spec.dependency 'RxGesture'
  spec.dependency 'SnapKit'
end
