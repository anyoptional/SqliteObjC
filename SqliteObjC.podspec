#
# Be sure to run `pod lib lint SqliteObjC.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SqliteObjC'
  s.version          = '1.0.0'
  s.summary          = 'Database abstraction layer, inspired by JDBC.'
  
  s.homepage         = 'Coming soon...'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Archer' => 'code4archer@163.com' }
  s.source           = { :git => 'Coming soon...', :tag => s.version.to_s }
  
  s.ios.deployment_target = '8.0'
  
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC', 'ENABLE_BITCODE' => 'NO' }
  
  s.subspec 'Core' do |cs|
    cs.public_header_files = 'SqliteObjC/Classes/Core/*.h'
    cs.source_files  = 'SqliteObjC/Classes/Core'
  end
  
  s.subspec 'Impls' do |cs|
    cs.source_files  = 'SqliteObjC/Classes/Impls'
    cs.public_header_files = 'SqliteObjC/Classes/Impls/*.h'
  end
  
  s.subspec 'Private' do |cs|
    cs.source_files  = 'SqliteObjC/Classes/Private'
    cs.private_header_files = 'SqliteObjC/Classes/Private/*.h'
  end

end
