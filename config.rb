activate :syntax
set :markdown_engine, :kramdown

set :current_version, 'v1.6'

# Make documentation for the latest version available at the top level, too.
# Any pages with names that conflict with files already at the top level will be skipped.
ready do
  sitemap.resources.each do |page|
    if page.path.start_with? "#{current_version}/"
      proxy_path = page.path["#{current_version}/".length..-1]
      proxy proxy_path, page.path if sitemap.find_resource_by_path(proxy_path).nil?
    end
  end
end

page '/sitemap.xml', layout: false

###
# Helpers
###
Dir.glob(File.expand_path('../helpers/**/*.rb', __FILE__), &method(:require))

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

activate :blog do |blog|
  blog.name = 'blog'
  blog.prefix = 'blog'
  blog.permalink = '{year}/{month}/{day}/{title}.html'
  blog.layout = 'blog_layout'
end

configure :development do
  # activate :livereload
end

configure :build do
  activate :minify_css
end
