require 'json'
require "yaml"
require_relative "datasource"
require_relative "outputwriter"
require_relative "page"

begin

	settings = YAML::load_file(File.join(__dir__, 'config.yaml'))

	dataSource = DataSource.new(settings)
	pages = dataSource.getLatestPages()
	pages = dataSource.removeOldArticles(pages)

	out = OutPutWriter.new(pages, settings)
	out.toHTML
	out.toHTMLHomepage
	out.toEmail
	
end
