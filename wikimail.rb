require 'json'
require "yaml"
require_relative "DataSource"
require_relative "OutPutWriter"
require_relative "Page"

begin

	settings = YAML::load_file(File.join(__dir__, 'config.yaml'))

	dataSource = DataSource.new(settings)
	pages = dataSource.getLatestPages()
	pages = dataSource.removeOldArticles(pages)

	out = OutPutWriter.new(pages, settings)
	out.toHTML
	out.toHTMLHomepage
	# out.toEmail
	
end
