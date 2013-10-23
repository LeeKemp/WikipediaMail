require 'json'
require 'mail'
require 'cgi'
require "yaml"
require_relative "page"

class OutPutWriter

	@@templateFileName = "template-day.html"
	@@homepageTemplateFileName = "template-home.html"

	def initialize(pages, settings)
    	@pages = pages
    	@settings = settings
    	@outputLocation = settings["outputdir"]

    	@t = Time.now
		@d = @t.strftime "%Y%m%d"
		@printDate = @t.strftime("%A %d %B %Y")
	end

	def toHTML()
		# Load the template
		template = File.read(@@templateFileName)
		fileName = @d  + ".html"
		outputHTML = "<h1>Popular Pages - #{@printDate} </h1>"

		for page in @pages
			outputHTML += "<h2> #{page.title}</h2>"
			if(page.extract)
				outputHTML += page.extract
			end
			outputHTML += "<a href='#{page.url}' >More...</a>"
			outputHTML += "<hr>"
		end

		outputHTML += "<!-- #{@t} -->"
		html = template.sub(/<<content>>/, outputHTML)

		File.open(@outputLocation + fileName, 'w') { |file| 
			file.write(html) 
		}
	end

	def toHTMLHomepage()

		outputHTML = '<table class="table table-striped">'

		files_sorted_by_time = 
		for item in Dir[@outputLocation + "*.html"].sort_by{ |f| File.stat(f).mtime }.reverse!
		  next if item == '.' or item == '..' or item == @outputLocation+'index.html'
		  date = Date.parse(item.sub(@outputLocation, '').sub(/.html/, ''))
		  outputHTML += '<tr><td><a href="'+item.sub(@outputLocation, '')+'" >'+date.strftime("%A %d %B %Y")+'</a></td></tr>'
		end
		outputHTML += '</table>'
		outputHTML += "<!-- #{@t} -->"

		template = File.read(@@homepageTemplateFileName)
		html = template.sub(/<<content>>/, outputHTML)

		File.open(@outputLocation + 'index.html', 'w') { |file| 
			file.write(html) 
		}
	end

	def toEmail()
		options = { :address          => @settings["email"]["address"],
	            :port                 => @settings["email"]["port"],
	            :domain               => @settings["email"]["domain"],
	            :user_name            => @settings["email"]["user_name"],
	            :password             => @settings["email"]["password"],
	            :authentication       => 'plain',
	            :enable_starttls_auto => true  
	        }
	            
		Mail.defaults do
		  delivery_method :smtp, options
		end

		subject = 'WikiMail - '+@printDate
		emailHTML = ""
		to=@settings["email"]["to"]
		from=@settings["email"]["from"]

		for page in @pages
			emailHTML += "<h1>#{page.title}</h1>"
			if(page.extract)
				emailHTML += page.extract
			end
			emailHTML += "<a href='#{page.url}' >More...</a>"
			emailHTML += "<hr>"
		end

		Mail.deliver do
			to to
			from from
			subject subject
			
			html_part do
	    		content_type 'text/html; charset=UTF-8'
	    		body emailHTML
	  		end
		end

	end # email

end