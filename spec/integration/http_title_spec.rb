require 'lib/http_title'

# Note: This spec depends upon the ability to contact a public website (Google)
# to run successfully
describe 'HttpTitle' do
  let(:http_title) { HttpTitle.new }
  context 'given a valid http uri' do
    it 'successfully gets the title from google.com' do
      expect(http_title.get('https://google.com')).to eq 'Google'
    end
    it 'correctly handles a URI object to get the title from google.com' do
      expect(http_title.get(URI::HTTPS.build(host: 'google.com'))).to eq 'Google'
    end
  end

  context 'given a non-http URI or any other string' do
    it 'errors if given a non-http URI string' do
      expect do
        http_title.get('file:///C/Users/pfaffle/file.txt')
      end.to raise_error('Not an HTTP/HTTPS URI')
    end
    it 'errors if given a non-http URI' do
      expect do
        http_title.get(URI::Generic.build(scheme: 'file', path: '/C/Users/pfaffle/file.txt'))
      end.to raise_error('Not an HTTP/HTTPS URI')
    end
  end
end
