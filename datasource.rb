require 'open-uri'
require 'json'
require_relative "Page"
require 'set'

class DataSource

	@@latestPageURL = "http://wikipedia.trending.eu/en/24hours.html" 
	@@latestPageRegexp = /(http:\/\/en.wikipedia.org\/wiki\/.*?)\"/
	@@titleRegexp = /http:\/\/en.wikipedia.org\/wiki\/(.+)/

	# https://www.mediawiki.org/wiki/Extension:MobileFrontend#prop.3Dextracts
	# http://en.wikipedia.org/w/api.php?action=parse&page=Amy_Lee&prop=text&format=html&section=0
	# http://www.mediawiki.org/wiki/API:Parsing_wikitext#parse
	@@contentUrlPrefix = "http://en.wikipedia.org/w/api.php?action=query&prop=extracts&exintro&exsectionformat=plain&format=json&titles="

	def initialize(settings)
    	@settings = settings
    	@outputLocation = settings["datadir"]

    	@t = Time.now
		@d = @t.strftime "%Y%m%d"
	end


	def getLatestPages()
		
		# Load todays data if it already exists.
		# Remove this to always load the data
		pages = loadTodaysData()
		if(pages)
			return pages
		end

		pages = Array.new
		pageHTML = ""

		open(@@latestPageURL) do |f|
  			pageHTML = f.read
		end

		pageHTML.scan(@@latestPageRegexp) { |p|  

			page = Page.new
			page.url = p[0]

			puts p[0]

			pageAPIurl = ""

			p[0].scan(@@titleRegexp) { |title|
				pageAPIurl = @@contentUrlPrefix + title[0]
				page.title = CGI::unescape(title[0].gsub(/_/, ' '))
			}

			begin

				# Get the extract from the Wikipedia API
				open(pageAPIurl) do |f|
					json = JSON.parse(f.read)
					page.extract = json["query"]["pages"][json["query"]["pages"].keys[0]]["extract"] # The 3rd value is the page id and changes 
				end
			rescue Exception => e
				puts "There was an error retrieving page, skipping"
				puts e.message  
  				puts e.backtrace.inspect 
			end

			pages.push(page)
		}

		serialize(pages)
		pages
	end

	def serialize(pages)
		serialized_object = YAML::dump(pages)
		fileName = @d  + ".yaml"

		File.open(@outputLocation + fileName, 'w') { |file| 
			file.write(serialized_object) 
		}
	end

	def loadTodaysData()
		loadDaysData(@d)
	end

	def loadDaysData(formattedDate)
		# Makes it quicker to test if we dont need to hit the API
		fileName = @outputLocation + formattedDate  + ".yaml"

		begin
			data = YAML::load_file(File.join(fileName))
		rescue
			return 
		end
	end

	#
	# Remove any articles that have been sent out in the past 7 days
	# Based on the title
	#
	def removeOldArticles(pages)
		start = DateTime.now - 1
		stop = DateTime.now - 8

		existingTitles = Set.new 

		# step back in time over two years, one week at a time
		start.step(stop, -1).each do |d| 
		    oldPages = loadDaysData(d.strftime "%Y%m%d")
		    if(oldPages)
		    	for oldPage in oldPages
		    		existingTitles.add(oldPage.title)
		    	end
		    end
		end

		deDupedPages = Array.new

		for page in pages
			if(!existingTitles.include?(page.title))

				puts("New Article ["+page.title+"]")

				deDupedPages.push(page)
			end
		end

		deDupedPages
	end

end
