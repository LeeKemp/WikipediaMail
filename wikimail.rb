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
	
	if(settings['env'] == 'prod')
		outputLocation = settings["outputdir"]
		puts `cd #{outputLocation} && git add -A && cd -`
		puts `cd #{outputLocation} && git commit -m "New Pages" && cd -`
		puts `cd #{outputLocation} && git push && cd -`
	end

end
