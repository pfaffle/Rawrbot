require 'plugins/Karma'

RSpec.describe 'Karma#display' do
  before(:each) do
    @bot = make_bot()
    @bot.loggers.level = :error
    @bot.plugins.register_plugin(Karma)
  end

  context 'key does not exist in the database' do
    it 'replies once' do
      msg = make_message(@bot, '!karma foo'
      replies = get_replies(msg)
      expect(replies.length).to eq 1
    end
    it 'shows karma as neutral' do
      msg = make_message(@bot, '!karma foo')
      replies = get_replies(msg)
      expect(replies[0].text).to eq 'foo has neutral karma.'
    end
    it 'derps' do
      msg = make_message(@bot, '!karma foo')
      replies = get_replies(msg)
      expect(replies).to eq nil
    end
  end
end
