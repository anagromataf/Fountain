# coding: utf-8
Pod::Spec.new do |s|
  s.name                    = "FTFountain"
  s.version                 = "2.3.3"
  s.summary                 = "Pluggable data sources and adapters for managing list-like content."
  
  s.authors                 = { "Tobias Kräntzer" => "info@tobias-kraentzer.de" }
  s.license                 = { :type => 'BSD', :file => 'LICENSE.md' }
  
  s.homepage                = 'https://github.com/anagromataf/Fountain'
  s.source                  = {:git => 'https://github.com/anagromataf/Fountain.git', :tag => "#{s.version}"}
  
  s.module_name             = "Fountain"
  s.requires_arc            = true
  s.ios.deployment_target   = '8.0'
  s.osx.deployment_target   = '10.10'
  
  s.source_files            = 'FTFountain/Common/**/*.{h,m,c}'
  s.ios.source_files        = 'FTFountain/iOS/**/*.{h,m,c}'
  s.osx.source_files        = 'FTFountain/OSX/**/*.{h,m,c}'
  
  s.frameworks = 'CoreData'
end
