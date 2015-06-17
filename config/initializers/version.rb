module Tarkin
  class Application 
    # Tarkin::Application::VERSION
    VERSION = "0.9.3 build #{`git rev-list HEAD | wc -l`.chomp.to_i}"
  end
end
