class Service::Databox < Service::Base
    title 'Databox'

    string :push_data_url, :placeholder => 'https://app.databox.com/service',
           :label => 'URL for your Crashlytics service'
    string :api_key, :placeholder => 'API key',
           :label => 'API key for your Crashlytics service'

    page 'Setup', [:push_data_url, :api_key]

    def receive_verification(config, _)
        begin
            url = "#{config[:push_data_url]}/logs"
            http.ssl[:verify] = false
            http.basic_auth config[:api_key], ''

            resp = http_get url
            if resp.status == 200
                [true,  'Successfully verified Databox settings!']
            else
                log "Databox HTTP Error, status code: #{ resp.status }, body: #{ resp.body }"
                [false, "Oops! Please check your settings again."]
            end
        rescue => e
            log "Rescued a verification error in Databox: (url=#{config[:push_data_url]}/logs) #{e}"
            [false, "Oops! Please check your settings again."]
        end
    end

    # Push data to Databox
    def receive_issue_impact_change(config, payload)
        http.ssl[:verify] = false
        http.basic_auth config[:api_key], ""

        post_body = {
            :data => [
                { :key => 'impacted_devices_count', :value => payload[:impacted_devices_count]},
                { :key => 'crashes_count', :value => payload[:crashes_count]}
            ]
        }

        resp = http_post config[:push_data_url] do |req|
            req.body = post_body.to_json
        end
        if resp.status != 200
            raise "Pushing data to Databox Failed: #{ resp[:status] }, #{ resp.body }"
        end
        :no_resource
    end
end
