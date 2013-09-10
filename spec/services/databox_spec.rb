require 'spec_helper'

describe Service::Databox do
	let(:testdata) do
    {
		:push_data_url => 'https://app.databox.com/push/custom/3rglns26g76sws04',
		:api_key => '5dc5qvbnb9wcwogww8w0g8g8scgo4swg'
    }
	end

	it 'should have a title' do
		Service::Databox.title.should == 'Databox'
	end

	it 'should require one page of information' do
		Service::Databox.pages.should == [
			{ :title => 'Setup', :attrs => [:push_data_url, :api_key] }
		]
	end

	describe :receive_verification do
		let(:service) { Service::Databox.new('log', {}) }
    	let(:config) do
    	{
    		:api_key => testdata[:api_key],
    		:push_data_url => testdata[:push_data_url]
    	}
    	end
  		let(:payload) { {} }

		it 'should respond' do
			service.respond_to?(:receive_verification)
		end

		it 'should succeed upon successful api response' do
			test = Faraday.new do |builder|
				builder.adapter :test do |stub|
					stub.get('/push/custom/3rglns26g76sws04') { [200, {}, ''] }
				end
			end

			service.should_receive(:http_get)
				.with('https://app.databox.com/push/custom/3rglns26g76sws04/logs')
				.and_return(test.get('/push/custom/3rglns26g76sws04'))

			resp = service.receive_verification(config, payload)
			resp.should == [true, 'Successfully verified Databox settings!']
		end

		it 'should fail upon unsuccessful api response' do
			test = Faraday.new do |builder|
				builder.adapter :test do |stub|
					stub.get('/push/custom/3rglns26g76sws04') { [500, {}, ''] }
				end
			end

			service.should_receive(:http_get)
				.with('https://app.databox.com/push/custom/3rglns26g76sws04/logs')
				.and_return(test.get('/push/custom/3rglns26g76sws04'))

			resp = service.receive_verification(config, payload)
			resp.should == [false, 'Oops! Please check your settings again.']
		end
	end

	describe :receive_issue_impact_change do
		let(:service) { Service::Databox.new('push', {}) }
    	let(:config) do
    	{
    		:api_key => testdata[:api_key],
    		:push_data_url => testdata[:push_data_url]
    	}
    	end
		let(:payload) do
		{
				:title => 'foo title',
				:impact_level => 1,
				:impacted_devices_count => 1,
				:crashes_count => 1,
				:app => {
					:name => 'foo name',
					:bundle_identifier => 'foo.bar.baz'
				}
		}
		end

		it 'should respond to receive_issue_impact_change' do
			service.respond_to?(:receive_issue_impact_change)
		end

		it 'should succeed upon successful api response' do
			test = Faraday.new do |builder|
				builder.adapter :test do |stub|
					stub.post('/push/custom/3rglns26g76sws04') { [200, {}, { response: { type: 'success', message: 'Items stored: 1' } }.to_json] }
				end
			end

			service.should_receive(:http_post)
				.with('https://app.databox.com/push/custom/3rglns26g76sws04')
				.and_return(test.post('/push/custom/3rglns26g76sws04'))

			resp = service.receive_issue_impact_change(config, payload)
			resp.should == :no_resource
		end

		it 'should fail upon unsuccessful api response' do
			test = Faraday.new do |builder|
				builder.adapter :test do |stub|
					stub.post('/push/custom/3rglns26g76sws04') { [500, {}, { response: { type: 'success', message: 'Items stored: 1' } }.to_json] }
				end
			end

			service.should_receive(:http_post)
				.with('https://app.databox.com/push/custom/3rglns26g76sws04')
				.and_return(test.post('/push/custom/3rglns26g76sws04'))

			lambda { service.receive_issue_impact_change(config, payload) }.should raise_error
		end
	end
end
