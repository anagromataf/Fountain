Pod::Spec.new do |s|
  s.name                    = "Fountain"
  s.version                 = "0.1-alpha1"
  s.summary                 = "Data Sources."
  s.authors                 = { "Tobias Kräntzer" => "info@tobias-kraentzer.de" }
  s.license                 = { :type => 'BSD', :file => 'LICENSE.md' }
  s.ios.deployment_target   = '8.0'
  s.requires_arc            = true
  s.source_files            = 'Fountain/Fountain/**/*.{h,m,c}'
end
