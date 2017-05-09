require 'lib/ldap_helper'

# Note: This test depends upon the ability to contact a public
# LDAP server to run successfully.
describe 'LdapHelper' do
  context 'using a public LDAP server' do
    let(:config) do
      {
        'server' => 'ldap.forumsys.com',
        'basedn' => 'dc=example,dc=com',
        'port' => port,
        'encryption' => encryption
      }
    end
    let(:user) { 'euler' }

    # Sadly, this public server isn't accessible over TLS
    context 'without TLS' do
      let(:port) { '389' }
      let(:encryption) { false }

      context 'without credentials' do
        it 'should successfully perform a search' do
          ldap = LdapHelper.new(config)
          results = ldap.search('uid', user)
          expect(results.first['uid']).to eq([user])
        end
      end

      context 'with credentials' do
        let(:binddn) { 'cn=read-only-admin,dc=example,dc=com' }
        let(:password) { 'password' }

        it 'should successfully authenticate' do
          config['username'] = binddn
          config['password'] = password
          ldap = LdapHelper.new(config)
          expect(ldap.bind).to be(true)
        end
        it 'should successfully perform a search' do
          config['username'] = binddn
          config['password'] = password
          ldap = LdapHelper.new(config)
          results = ldap.search('uid', user)
          expect(results.first['uid']).to eq([user])
        end
      end
    end
  end
end
