#
# Be sure to run `pod lib lint TNSQLDB.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TNSQLDB'
  s.version          = '0.0.1'
  s.summary          = 'A short description of TNSQLDB.'

  s.description      = 'sql objectification'

  s.homepage         = 'https://github.com/l-h-d/TNSQLDB'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'l-h-d' => 'lhd20084978@foxmail.com' }
  s.source           = { :git => 'https://github.com/l-h-d/TNSQLDB.git', :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'

  s.source_files = 'TNSQLDB/**/*'

  s.dependency 'FMDB'
end
