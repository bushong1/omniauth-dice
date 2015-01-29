require 'spec_helper'

describe OmniAuth::Strategies::Dice do
  let!(:app)            { TestRackApp.new }
  let(:invalid_subject) { OmniAuth::Strategies::Dice.new(app) }
  let(:dice_default_opts) { {
    cas_server: 'https://dice.dev',
    authentication_path: '/users'
  } }
  let(:valid_subject)   {
    OmniAuth::Strategies::Dice.new(app, dice_default_opts )
  }
  let!(:client_dn_from_cert) { '/DC=org/DC=ruby-lang/CN=Ruby certificate rbcert' }
  let(:client_dn_reversed)   { client_dn_from_cert.split('/').reverse.join('/') }
  let(:formatted_client_dn)  { 'CN=RUBY CERTIFICATE RBCERT,DC=RUBY-LANG,DC=ORG' }

  # Travis-CI hack?
  before(:all) do
    @rack_env = ENV['RACK_ENV']
    ENV['RACK_ENV'] = 'test'
  end

  context "invalid params" do
    subject { invalid_subject }
    let(:subject_without_authentication_path) { OmniAuth::Strategies::Dice.new(app, cas_server: 'https://dice.dev') }

    it 'should require a cas server url' do
      expect{ subject }.to raise_error(RequiredCustomParamError, "omniauth-dice error: cas_server is required")
    end

    it 'should require an authentication path' do
      expect{ subject_without_authentication_path }.to raise_error(RequiredCustomParamError, "omniauth-dice error: authentication_path is required")
    end
  end

  context "defaults" do
    subject { valid_subject }
    it 'should have the correct name' do
      expect(subject.options.name).to eq('dice')
    end

    it "should return the default options" do
      expect(subject.options.format).to        eq('json')
      expect(subject.options.format_header).to eq('application/json')
    end
  end

  context "configured with options" do
    subject { valid_subject }

    it 'should have the configured CAS server URL' do
      expect(subject.options.cas_server).to eq("https://dice.dev")
    end

    it 'should have the configured authorization path' do
      expect(subject.options.authentication_path).to eq('/users')
    end
  end

  context ".format_dn" do
    subject { valid_subject }

    it 'should ensure the client DN format is in the proper order' do
      formatted_cert_dn = subject.format_dn(client_dn_from_cert)
      expect(formatted_cert_dn).to eq(formatted_client_dn)

      formatted_reverse_client_dn = subject.format_dn(client_dn_reversed)
      expect(formatted_reverse_client_dn).to eq(formatted_client_dn)
    end
  end

  context ".set_name" do
    before do
      @info_hash = {
        'common_name' => 'twilight.sparkle',
        'full_name'   => 'Princess Twilight Sparkle',
        'first_name'  => 'twilight',
        'last_name'   => 'sparkle'
      }
    end

    it 'should not set a name field if it is already defined' do
      dice = OmniAuth::Strategies::Dice.new( app, dice_default_opts )
      name = dice.send( :set_name, @info_hash.merge({'name' => 'nightmare moon'}) )
      expect(name).to eq('nightmare moon')
    end

    it 'should default to :cn then :first_name and finally :first_last_name' do
      dice = OmniAuth::Strategies::Dice.new( app, dice_default_opts )
      # With only full_name available
      name = dice.send(:set_name, { 'full_name' => @info_hash['full_name'] })
      expect(name).to eq(@info_hash['full_name'])
      # With only first_name and last_name available
      name = dice.send(:set_name, { 'first_name' => @info_hash['first_name'], 'last_name' => @info_hash['last_name'] })
      expect(name).to eq("#{@info_hash['first_name']} #{@info_hash['last_name']}")
      # With only the dn available
      name = dice.send(:set_name, { 'common_name' => @info_hash['common_name'] })
      expect(name).to eq(@info_hash['common_name'])
    end

    it 'should support custom name formatting set as :cn' do
      dice = OmniAuth::Strategies::Dice.new( app, dice_default_opts.merge({name_format: :cn}) )
      name = dice.send(:set_name, @info_hash)
      expect(name).to eq(@info_hash['common_name'])
    end

    it 'should support custom name formatting set as :full_name' do
      dice = OmniAuth::Strategies::Dice.new( app, dice_default_opts.merge({name_format: :full_name}) )
      name = dice.send(:set_name, @info_hash)
      expect(name).to eq(@info_hash['full_name'])
    end

    it 'should support custom name formatting set as :first_last_name' do
      dice = OmniAuth::Strategies::Dice.new( app, dice_default_opts.merge({name_format: :first_last_name}) )
      name = dice.send(:set_name, @info_hash)
      expect(name).to eq("#{@info_hash['first_name']} #{@info_hash['last_name']}")
    end
  end

  context ".identify_npe" do
    pending
    it "should identify a client as a likely npe when the CN contains a *.tld" do
    end

    it "should identify a client as a likely npe when there is a DN & no email" do
    end

    it "should identify a client as a likely npe when there is a DN, email, and NO name fields" do
    end

    it "should identify a client as not an npe when there is a DN, email, and ANY name field" do
    end
  end
end
