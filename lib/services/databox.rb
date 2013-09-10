# encoding: utf-8

# The Service::Databox is a class responsible for handling Databox.com
# Connection settings and acting in response to events it receives from
# Crashlytics
class Service::Databox < Service::Base
  title 'Databox'

  string :push_url, label: 'URL'
  string :push_token, label: 'Token'

  page 'Push Connection Settings', [:push_url, :push_token]

  def receive_verification(config, _)
    url               = "#{config[:push_url]}/logs"
    http.ssl[:verify] = true
    http.basic_auth config[:push_token], ''

    resp = http_get url
    if resp.status == 200
      [true,  'Successfully verified Databox connection!']
    else
      log "Databox HTTP Error, status code: #{resp.status}, body: #{resp.body}"
      [false, 'Oops! Please check your settings again.']
    end
  rescue => exception
    log "Rescued a verification error in Databox: (url=#{url}) #{exception}"
    [false, 'Oops! Please check your settings again.']
  end

  # Push data to Databox
  def receive_issue_impact_change(config, payload)
    http.ssl[:verify] = true
    http.basic_auth config[:push_token], ''

    post_body = {
      data: [
        { key: 'impacted_devices_count', value: payload[:impacted_devices_count] },
        { key: 'crashes_count', value: payload[:crashes_count] }
      ]
    }

    resp = http_post config[:push_url] do |req|
      req.body = post_body.to_json
    end
    if resp.status != 200
      raise "Pushing data to Databox Failed: #{resp[:status]}, #{resp.body}"
    end
      :no_resource
  end
end