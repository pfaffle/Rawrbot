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
# 	A file with authentication information for RT.
class RTSearch
	include Cinch::Plugin
	
	require 'net/http'
	require 'net/https'

	match("help", method: :help)
	match(/help rtsearch|help rt/i, method: :rt_help)
	match(/(\d{6})/, :use_prefix => false, method: :execute)

	# Function: execute
	# 
	# Description: Perform the search on RT. Retrieve ticket number and basic
	# 	ticket details.
	def execute(m,tnumber)
		require "$pwd/plugins/rt_auth.rb"

		ticket = Hash.new
		puts "Executing RT search.."
		# Format the HTTP request.
		http = Net::HTTP.new('support.oit.pdx.edu', 443)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		rt_auth = rt_return_auth
		login = "user=#{rt_auth['username']}&pass=#{rt_auth['pass']}"
		headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

		# Execute the HTTP request.
		resp, data = http.post("/REST/1.0/ticket/#{tnumber}/show",login,headers)
		
		# Parse the data retrieved about the ticket into a Hash variable.
		data = data.split(/\n+/)
		data.each do |element|
			if element.match(/([^:]+): ?(.+)/)
				ticket[$1] = [$2]
				puts "key = #{$1}     value = #{$2}"
			elsif element.match(/([^:]+):/)
				ticket[$1] = ''
				puts "key = #{$1}     value = nil"
			end
		end
		
		# Reply with ticket information.
		m.reply "$#{tnumber}: #{ticket['Subject']} - #{ticket['Requestors']} - (#{ticket['Owner']})"

	end # End of execute function

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
