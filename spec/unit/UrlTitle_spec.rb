require 'plugins/UrlTitle'
require 'lib/http_title'

def message(text)
  make_message(@bot, text, channel: '#testchan')
end

RSpec.describe 'UrlTitle' do
  before(:each) do
    @mock_http_title = instance_double(HttpTitle)
    @bot = new_bot_with_plugins(UrlTitle)
    @bot.plugins.first.use_http_title(@mock_http_title)
  end

  it 'gets the title of a website' do
    url = 'https://google.com'
    title = 'My website title'
    allow(@mock_http_title).to receive(:get).with(URI.parse(url)).and_return(title)
    replies = get_replies(message(url))
    expect(replies.first.text).to eq title
    expect(replies.length).to eq 1
  end

  it 'gets the title of a website with other text on the line' do
    url = 'https://google.com'
    title = 'My website title'
    allow(@mock_http_title).to receive(:get).with(URI.parse(url)).and_return(title)
    replies = get_replies(message("hey check out this website #{url}"))
    expect(replies.first.text).to eq title
    expect(replies.length).to eq 1
  end

  it 'gets the title of multiple websites on one line' do
    websites = [
      {
        url: 'https://google.com',
        title: 'My website title'
      }, {
        url: 'https://yahoo.com',
        title: 'My other website'
      }
    ]
    websites.each do |website|
      allow(@mock_http_title).to receive(:get).with(URI.parse(website[:url])).and_return(website[:title])
    end
    replies = get_replies(message("my websites #{websites[0][:url]} and #{websites[1][:url]}"))
    replies.each_with_index do |reply, index|
      expect(reply.text).to eq websites[index][:title]
    end
    expect(replies.length).to eq 2
  end
end
