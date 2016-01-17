require 'plugins/Karma'

RSpec.describe 'Karma#display' do
  context 'key does not exist in the database' do
    it 'shows karma as 0' do
      # TODO: Figure out how to use Cinch::Test in here
      bot = Cinch::Test.make_bot('Karma')
      msg = Cinch::Test.make_message(bot, '!karma foo')
      Cinch::Test.get_replies(msg).each do |reply|
        expect(reply).to eq 'foo has karma of 0'
      end
    end
  end
end
