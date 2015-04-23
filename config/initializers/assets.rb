# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( sessions.js directories.js )
Rails.application.config.assets.precompile += %w( admin/groups.js )
Rails.application.config.assets.precompile += %w( jquery-tablesorter/dropbox-asc.png jquery-tablesorter/dropbox-desc.png jquery-tablesorter/dropbox-asc-hovered.png jquery-tablesorter/dropbox-desc-hovered.png ) 
Rails.application.config.assets.precompile += %w( admin/users.js )
# Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/

# Rails.application.config.assets.precompile << Proc.new do |path|
#   if path =~ /\.(css|js|svg|eot|woff|ttf)\z/
#     full_path = Rails.application.assets.resolve(path).to_path
#     app_assets_path = Rails.root.join('app', 'assets').to_path
#     if full_path.starts_with? app_assets_path
#       # puts "including asset: " + full_path
#       true
#     else
#       # puts "excluding asset: " + full_path
#       false
#     end
#   else
#     false
#   end
# end
