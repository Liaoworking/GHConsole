Pod::Spec.new do |s|
s.name         = 'GHConsole'
s.version      = '1.0.2'
s.summary          = 'A easily way to show your console in your app.'
s.homepage     = 'https://github.com/liaoworking/GHConsole'
s.license      = 'MIT'
s.authors      = {'liaoWorking' => 'liaoWorking@gmail.com'}
s.platform     = :ios, '7.0'
s.source           = { :git => 'https://github.com/liaoworking/GHConsole.git', :tag => s.version}
s.source_files = 'GHConsole/GHConsole/**/*'
s.requires_arc = true
end
