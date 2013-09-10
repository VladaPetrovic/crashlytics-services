# encoding: utf-8

require 'spec_helper'

describe Service::Databox do
  let(:base_url)         { 'https://app.databox.com' }
  let(:service_push_url) { '/push/custom/3rglns26g76sws04' }
  let(:fixtures) do
    {
      config: {
        push_url:   "#{base_url}#{service_push_url}",
        push_token: '5dc5qvbnb9wcwogww8w0g8g8scgo4swg'
      },
      response: {
        response: {
          type: 'success',
          message: 'Items stored: 1'
        }.to_json
      }
    }
  end

  it 'should have a title' do
    Service::Databox.title.should == 'Databox'
  end

  it 'should require one page of information' do
    Service::Databox.pages.should == [
      { title: 'Push Connection Settings', attrs: [:push_url, :push_token] }
    ]
  end

  describe :receive_verification do
    let(:service) { Service::Databox.new('logs', {}) }
    let(:payload) { {} }

    it 'should respond' do
      service.respond_to?(:receive_verification)
    end

    it 'should succeed upon successful API response' do
      test = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.get(service_push_url) { [200, {}, ''] }
        end
      end

      service.should_receive(:http_get)
        .with("#{fixtures[:config][:push_url]}/logs")
        .and_return(test.get(service_push_url))

      resp = service.receive_verification(fixtures[:config], payload)
      resp.should == [true, 'Successfully verified Databox connection!']
    end

    it 'should fail upon unsuccessful API response' do
      test = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.get(service_push_url) { [500, {}, ''] }
        end
      end

      service.should_receive(:http_get)
        .with("#{fixtures[:config][:push_url]}/logs")
        .and_return(test.get(service_push_url))

      resp = service.receive_verification(fixtures[:config], payload)
      resp.should == [false, 'Oops! Please check your settings again.']
    end
  end

  describe :receive_issue_impact_change do
    let(:service) { Service::Databox.new('push', {}) }
    let(:payload) do
      {
        title:                  'issue title',
        method:                 'method name',
        impact_level:           1,
        impacted_devices_count: 1,
        crashes_count:          1,
        app: {
          name:              'app name',
          bundle_identifier: 'foo.bar.baz',
          platform:          'ios'
        },
        url: 'http://foo.com/bar'
      }
    end

    it 'should respond to receive_issue_impact_change' do
      service.respond_to?(:receive_issue_impact_change)
    end

    it 'should succeed upon successful API response' do
      test = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.post(service_push_url) { [200, {}, fixtures[:response]] }
        end
      end

      service.should_receive(:http_post)
        .with(fixtures[:config][:push_url])
        .and_return(test.post(service_push_url))

      resp = service.receive_issue_impact_change(fixtures[:config], payload)
      resp.should == :no_resource
    end

    it 'should fail upon unsuccessful API response' do
      test = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.post(service_push_url) { [500, {}, fixtures[:response]] }
        end
      end

      service.should_receive(:http_post)
        .with(fixtures[:config][:push_url])
        .and_return(test.post(service_push_url))

      -> { service.receive_issue_impact_change(fixtures[:config], payload) }
        .should raise_error
    end
  end
end