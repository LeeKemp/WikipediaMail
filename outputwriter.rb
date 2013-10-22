require 'json'
require 'mail'
require 'cgi'
require "yaml"
require_relative "Page"

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
		outputHTML = "<h1>Popular Pages - " + @printDate + "</h1>"

		for page in @pages
			outputHTML += "<h2>" + page.title + "</h2>"
			outputHTML += page.extract
			outputHTML += "<a href='"+page.url+"' >More...</a>"
			outputHTML += "<hr>"
		end

		html = template.sub(/<<content>>/, outputHTML)

		File.open(@outputLocation + fileName, 'w') { |file| 
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
			emailHTML += "<h1>" + page.title + "</h1>"
			emailHTML += page.extract
			emailHTML += "<a href='"+page.url+"' >More...</a>"
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