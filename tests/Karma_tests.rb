require 'cinch'
require 'cinch/test'
require 'test/unit'
load 'plugins/Karma.rb'

class KarmaTests < Test::Unit::TestCase
    include Cinch::Test

    def test_help()
        bot = make_bot(Karma)
        msg = make_message(bot, '!help')
        resp = get_replies(msg)
        assert_equal(false,resp.empty?,"Plugin did not respond")
        reply = resp[0][:text]
        if reply
        assert_equal("See: !help karma",reply)
    end

    def strip_anchor!(str)
        str.delete! str[0] if str.start_with? '^'
        str.delete! str[str.size] if str.end_with? '$'
    end

end
