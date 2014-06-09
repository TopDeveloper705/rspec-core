source "https://rubygems.org"

gemspec

branch = File.read(File.expand_path("../maintenance-branch", __FILE__)).chomp
%w[rspec rspec-expectations rspec-mocks rspec-support].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "git://github.com/rspec/#{lib}.git", :branch => branch
  end
end

gem 'yard', '~> 0.8.7', :require => false

### deps for rdoc.info
group :documentation do
  gem 'redcarpet',     '2.1.1'
  gem 'github-markup', '0.7.2'
end

platforms :ruby_18, :jruby do
  gem 'json'
end

platforms :jruby do
  gem "jruby-openssl"
end

gem 'simplecov', '~> 0.8'

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
