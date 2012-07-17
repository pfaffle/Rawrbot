# =============================================================================
# Plugin: RTSearch
#
# Description:
# 	Enables rawrbot to search OIT's Request Tracker ticketing system for basic
# 	ticket data. This plugin simply notices when something appears like a ticket
# 	number, then returns basic info about that ticket such as the Subject,
# 	the Requestors, current Status, and Owner.
#
# Requirements:
# 	A file 'auth_rt.rb' with authentication information for RT.
class RTSearch
	include Cinch::Plugin
	
	require 'net/http'
	require 'net/https'

	match("help", method: :help)
	match(/help rtsearch|help rt/i, method: :rt_help)
	match(/(\d{1,6})/, :use_prefix => false)
	
	def execute(m,tnumber)
		# only perform ticket number searches in #helpdesk for security reasons.
		# REMINDER: COMMENT THIS WHEN TESTING.
		if m.channel == "#helpdesk"
			# The ticket_list hash is structured like so:
			# ticket_list["ticketnumber"] = verbose_flag
			ticket_list = Hash.new

			# Assemble a list of ticket numbers to search for.
			templist = m.message.scan(/(rt#|rt|#)?(\d{1,6})\b/i)
			if (!templist.nil?)
				# Filter out entries that are probably not ticket numbers.
				templist.each do |maybeticket|
					if (maybeticket[0].nil?)
						# Did not have a 'rt' and/or '#' prefix to the number.
						# Don't be verbose with these.
						if (maybeticket[1].size() == 6)
							ticket_list["#{maybeticket[1]}"] = false
						end
					else
						# Explicitly marked as a ticket number with "#" or "RT#".
						# Be verbose if not a valid ticket.
						if (maybeticket[1].size() < 7)
							ticket_list["#{maybeticket[1]}"] = true
						end
					end
				end
			end

			if (ticket_list.size() > 0)
				rt_search m,ticket_list
			end
		elsif (m.message =~ /rt#\d{1,6}\b/i)
			m.reply "Ticket searches not allowed here."
		end
	end # End of execute function

	# Function: rt_search
	# 
	# Description: Perform the search on RT. Retrieve ticket number and basic
	# 	ticket details.
	def rt_search(m,ticket_list)
		load "#{$pwd}/plugins/auth_rt.rb"
		ticket = Hash.new
		# Format the HTTP request.
		http = Net::HTTP.new('support.oit.pdx.edu', 443)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		rt_auth = rt_return_auth
		login = "user=#{rt_auth['username']}&pass=#{rt_auth['pass']}"
		headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

		# Execute the HTTP requests.
		ticket_list.each do |tnumber,verbose|
			resp, data = http.post("/NoAuthCAS/REST/1.0/ticket/#{tnumber}/show",login,headers)
		
			# If there is a '#' symbol immediately after RT's acknowledgement of the request,
			# it indicates an error message signifying that the ticket could not be displayed.
			if data =~ /^RT\/\d(\.\d+)+ 200 Ok\n\n#/
				if verbose
					m.reply "Ticket ##{tnumber} could not be displayed.\n"
				end
			else
			# Parse the data retrieved about the ticket into a Hash variable.
				data = data.split(/\n+/)
				data.each do |element|
					if element.match(/([^:]+): ?(.+)/)
						ticket[$1] = $2
					elsif element.match(/([^:]+):/)
						ticket[$1] = ''
					end
				end
				# Reply with ticket information.
				m.reply "#{tnumber} | #{ticket['Requestors']} | #{ticket['Owner']} | #{ticket['Subject']}"
			end
		end
	end # End of rt_search function

	# Function: help
	#
	# Description: Adds onto the generic help function for other plugins. Prompts
	#   people to use a more specific command to get more details about the
	#   functionality of the module specifically.
	def help(m)
		m.reply "See: !help rtsearch"
	end # End of help function
	
	# Function: rt_help
	#
	# Description: Displays help information for how to use the plugin.
	def rt_help(m)
		m.reply "RT Search"
		m.reply "==========="
		m.reply "Display RT ticket information."
		m.reply "Usage: rt#[ticket number]" 
	end

end
# End of plugin: RTSearch
# =============================================================================
