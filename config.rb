Dir.glob(File.expand_path('../lib/config/*.rb', __FILE__), &method(:require))

config[:versions] = `rake versions`.split
config[:current_version] = config[:versions].last

activate :syntax
activate :i18n
activate :search do |search|
  search.resources = ['index.html', 'guides/', "#{config[:current_version]}/", 'compatibility.html', 'conduct.html', 'contributors.html']

  search.index_path = 'search/lunr-index.json'

  search.fields = {
    title: {boost: 100, store: true, required: true},
    content: {boost: 50},
    url: {index: false, store: true},
    description: {index: false, store: true},
  }
end

set :markdown_engine, :kramdown

# Markdown extentions
set :markdown,
    autolink: true,
    fenced_code_blocks: true,
    footnotes: true,
    gh_codeblock: true,
    highlight: true,
    no_intra_emphasis: true,
    quote: true,
    smartypants: true,
    strikethrough: true,
    superscript: true,
    tables: true

# Webpack
activate :external_pipeline,
 name: :webpack,
 command: build? ? "npm run build" : "npm run start",
 source: ".tmp/dist",
 latency: 1

set :images_dir, 'images'

# Make documentation for the latest version available at the top level, too.
# Any pages with names that conflict with files already at the top level will be skipped.
Dir.glob("./source/#{config[:current_version]}/**/*").select{ |f| File.file?(f) }.each do |file_path|
  file_path = file_path.sub(/(\.haml$|\.md$)/, '')

  page_path = file_path.sub(/^\.\/source\//, '')
  proxy_path = file_path["./source/#{config[:current_version]}/".length..-1]

  proxy proxy_path, page_path unless file_exist?(proxy_path)
end
# Same for localizable
Dir.glob("./source/localizable/#{config[:current_version]}/**/*").select{ |f| File.file?(f) }.each do |file_path|
  matched = file_path.match(/(localizable\/v\d+.\d+\/(.*)\.(.{2})\.html)/)
  next unless matched

  page_path = matched[1]
  proxy_path = "#{matched[2]}.html"
  country = matched[3]

  next if file_exist?(proxy_path)

  proxy "#{country}/#{proxy_path}", page_path, locale: country.to_sym
  proxy proxy_path, page_path, locale: :en if country == 'en'
end

# Workaround for https://github.com/rubygems/bundler-site/pull/44 for 9 years
%w[bundler_workflow gemfile gemfile_ruby rationale rubygems rubymotion].each do |filename|
  redirect "#{filename}.html", to: "guides/#{filename}.html"
end

# Proxy man generated documentation to be available at /vX.XX/ (for compatibility with old guides)
# Ex: /v1.12/man/bundle-install.1.html.erb available at /v1.12/bundle_install.html
config[:versions].each do |version|
  Dir.glob("./source/#{version}/man/**/*").select{ |f| File.file?(f) }.each do |file_path|
    file_path = file_path[0..-5]
    page_path = file_path.sub(/^\.\/source/, '')

    man_page_name_matched = file_path.match(/man\/(.*)\.html$/)
    next unless man_page_name_matched

    man_page_name = man_page_name_matched[1].gsub(/\.\d+$/, '').gsub('-', '_')
    man_page_name = 'gemfile_man' if man_page_name == 'gemfile'

    proxy "/#{version}/#{man_page_name}.html", page_path unless man_page_exists?(man_page_name, version)
  end
end

%w[1.12 1.13 1.14].each do |version|
  %w[bundler_setup bundler_sharing deploying faq git_bisect git groups rails sinatra updating_gems].each do |filename|
    redirect "v#{version}/guides/#{filename}.html", to: "v1.15/guides/#{filename}.html"
  end

  # Redirect old localizable guides (v1.12-v1.14) to the latest version (1.15) of guide compatible with Ruby 1.8.x
  ["", "pl/"].each do |lang|
    redirect "#{lang}v#{version}/guides/creating_gem.html", to: "#{lang}v1.15/guides/creating_gem.html"
    redirect "#{lang}v#{version}/guides/using_bundler_in_applications.html", to: "#{lang}v1.15/guides/using_bundler_in_applications.html"
  end
end
%w[rails23 rails3].each do |filename|
  redirect "v1.12/guides/#{filename}.html", to: "v1.15/guides/#{filename}.html"
end

# Redirect versioned-guides (which are not localizable) between v1.16 and v2.3 to version-independent guides
%w[1.16 1.17 2.0 2.1 2.2 2.3].each do |version|
  redirect "v#{version}/guides/bundler_docker_guide.html", to: "guides/bundler_docker_guide.html"
  redirect "v#{version}/guides/bundler_in_a_single_file_ruby_script.html", to: "guides/bundler_in_a_single_file_ruby_script.html"
  redirect "v#{version}/guides/bundler_plugins.html", to: "guides/bundler_plugins.html"
  redirect "v#{version}/guides/bundler_setup.html", to: "guides/bundler_setup.html"
  redirect "v#{version}/guides/bundler_sharing.html", to: "guides/bundler_sharing.html"
  redirect "v#{version}/guides/deploying.html", to: "guides/deploying.html"
  redirect "v#{version}/guides/faq.html", to: "guides/faq.html"
  redirect "v#{version}/guides/git.html", to: "guides/git.html"
  redirect "v#{version}/guides/git_bisect.html", to: "guides/git_bisect.html"
  redirect "v#{version}/guides/groups.html", to: "guides/groups.html"
  redirect "v#{version}/guides/rails.html", to: "guides/rails.html"
  redirect "v#{version}/guides/rubygems_tls_ssl_troubleshooting_guide.html", to: "guides/rubygems_tls_ssl_troubleshooting_guide.html"
  redirect "v#{version}/guides/sinatra.html", to: "guides/sinatra.html"
  redirect "v#{version}/guides/updating_gems.html", to: "guides/updating_gems.html"

  # Redirect old localizable guides (v1.16-v2.3) to the current (version-independent) guide
  ["", "pl/"].each do |lang|
    redirect "#{lang}v#{version}/guides/creating_gem.html", to: "#{lang}guides/creating_gem.html"
    redirect "#{lang}v#{version}/guides/using_bundler_in_applications.html", to: "#{lang}guides/using_bundler_in_applications.html"
  end
end
# Redirect versioned-guides (which are not localizable) between v2.0 and v2.3 to version-independent guides
%w[2.0 2.1 2.2 2.3].each do |version|
  redirect "v#{version}/guides/bundler_2_upgrade.html", to: "guides/bundler_2_upgrade.html"
end

redirect "sponsors.html", to: "https://rubygems.org/pages/sponsors" # Backwards compatibility

page '/conduct.html', layout: :guides_layout
page '/compatibility.html', layout: :guides_layout
page /\/v(\d+.\d+)\/(?!bundle_|commands|docs|man)(.*)/, layout: :md_guides_layout
page /\/v(.*)\/bundle_(.*)/, layout: :commands_layout
page /\/v(.*)\/man\/(.*)/, layout: :commands_layout
page /\/man\/(.*)/, layout: :commands_layout
page /\/v(.*)\/commands\.html/, layout: :commands_layout
page /\/v(.*)\/guides\/(.*)/, layout: :md_guides_layout
page /guides\/(.*)/, layout: :md_guides_layout
page /\/doc\/(.*)/, layout: :md_guides_layout # Imported from bundler/bundler

page '/sitemap.xml', layout: false

redirect "issues.html", to: "doc/contributing/issues.html" # Backwards compatibility
redirect "commands.html", to: "man/bundle.1.html" # Backwards compatibility
redirect "older_versions.html", to: "whats_new.html" # Backwards compatibility

###
# Helpers
###
Dir.glob(File.expand_path('../helpers/**/*.rb', __FILE__), &method(:require))
helpers CommandReferenceHelper
helpers ConfigHelper
helpers DocsHelper
helpers AvatarHelper

activate :blog do |blog|
  blog.name = 'blog'
  blog.prefix = 'blog'
  blog.permalink = '{year}/{month}/{day}/{title}.html'
  blog.layout = 'blog_layout'

  blog.calendar_template = 'blog/calendar.html'
  blog.year_link = "{year}/index.html"
  blog.month_link = "{year}/{month}/index.html"
  blog.day_link = "{year}/{month}/{day}/index.html"
end

page "/blog/feed.xml", layout: false

configure :development do
  config[:css_dir] = ".tmp/dist"
  config[:js_dir] = ".tmp/dist"
end

configure :build do
  config[:css_dir] = ""
  config[:js_dir] = ""
end
