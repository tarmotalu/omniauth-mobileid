require 'digidoc/client'
require 'ostruct'

module OmniAuth
  module Strategies
    class Mobileid
      include OmniAuth::Strategy

      PhaseReadPin = 'read_pin'
      PhaseAuhtenticated = 'authenticated'

      option :name, 'mobileid'
      option :service_name, 'Testimine'
      option :country_code, 'EE'
      option :language, 'EST'
      option :message_to_display, 'Test'
      option :messaging_mode, 'asynchClientServer'
      option :async_configuration, 0
      option :endpoint_url, 'https://openxades.org:8443/DigiDocService'
      option :logger, nil

      def request_phase
        perform
      end

      def perform
        if request_session_code # Session is in :read_pin status
          get_authentication_status
        else
          perform_authentication
        end
      end

      def request_session_code
        request.params['session_code']
      end

      def perform_authentication
        debug 'perform_authentication'
        @auth_data = authenticate(request.params['phone'], request.params['personal_code'])
        debug user_data.inspect

        if user_data[:status] == 'OK'
          @env['omniauth.auth'] = auth_hash
          @env['omniauth.phase'] = PhaseReadPin
          @env['REQUEST_METHOD'] = 'GET'
          @env['PATH_INFO'] = "#{OmniAuth.config.path_prefix}/#{name}/callback"
          call_app!
        else
          fail!(failure_reason)
        end
      end

      def get_authentication_status
        debug 'get_authentication_status'
        @auth_data = authentication_status(request_session_code)
        debug @auth_data.inspect

        if ['USER_AUTHENTICATED', 'OUTSTANDING_TRANSACTION'].include?(user_data[:status])
          @env['omniauth.phase'] = user_data[:status] == 'USER_AUTHENTICATED' ? PhaseAuhtenticated : PhaseReadPin
          @env['REQUEST_METHOD'] = 'GET'
          @env['PATH_INFO'] = "#{OmniAuth.config.path_prefix}/#{name}/callback"
          call_app!
        else
          fail!(failure_reason)
        end
      end

      def callback_phase
        debug "callback_phase"
        fail!(failure_reason)
      end

      def failure_reason
        return :invalid_credentials if user_data.blank?

        code = (user_data[:faultstring] || user_data[:status]).try(:downcase)
        "error_#{code || 'unknown'}"
      end

      def user_data
        @auth_data
      end

      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
          'uid' => user_data[:user_id_code],
          'user_info' => user_info,
          'read_pin' => {
             'challenge_id' => user_data[:challenge_id],
             'session_code' => user_data[:sesscode]},
          'extra' => {'user_hash' => user_data}
        })
      end

      def user_info
        {
          'name' => "#{user_data[:user_givenname]} #{user_data[:user_surname]}",
          'first_name' => user_data[:user_givenname],
          'last_name' => user_data[:user_surname],
          'personal_code' => user_data[:user_id_code],
          'user_cn' => user_data[:user_cn]
        }
      end

      # Authentication message
      def authenticate(phone, personal_code)
        data = {
          :phone => phone,
          :personal_code => personal_code,
          :language => options[:language],
          :country_code => options[:country_code],
          :message_to_display => options[:message_to_display],
          :service_name => options[:service_name],
          :messaging_mode => options[:messaging_mode],
          :async_configuration => options[:async_configuration],
          :return_cert_data => false,
          :return_revocation_data => false
        }

        self.mobileid_client.authenticate(data)
      end

      # Authentication status message
      def authentication_status(session_code)
        self.mobileid_client.authentication_status(session_code)
      end

      protected

      def debug(message)
        options[:logger].debug("#{Time.now} #{message}") if options[:logger]
      end

      def mobileid_client
        client = ::Digidoc::Client.new(options[:endpoint_url])
        client.respond_with_nested_struct = false
        client
      end
    end
  end
end