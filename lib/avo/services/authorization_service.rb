module Avo
  module Services
    class AuthorizationService
      class PolicyNotDefinedError < StandardError; end
      class NotAuthorizedError < StandardError; end

      attr_accessor :user, :record

      class << self
        def client
          client_klass =
            case Avo.configuration.authorization_client
            when :pundit
              'Avo::Services::AuthorizationClient::PunditClient'.constantize
            when :action_policy
              'Avo::Services::AuthorizationClient::ActionPolicyClient'.constantize
            else
              Avo.configuration.authorization_client
            end
          client_klass.new
        end

        def authorize(user, record, action, **args)
          return true if skip_authorization
          return true if user.nil?

          begin
            if client.policy(user, record)
              client.authorize user, record, action
            end

            true
          rescue PolicyNotDefinedError => e
            return false unless Avo.configuration.raise_error_on_missing_policy

            raise e
          rescue StandardError => e
            if args[:raise_exception] == false
              false
            else
              raise e
            end
          end
        end

        def authorize_action(user, record, action, **args)
          action = Avo.configuration.authorization_methods.stringify_keys[action.to_s] || action

          # If no action passed we should raise error if the user wants that.
          # If not, just allow it.
          if action.nil?
            raise PolicyNotDefinedError, 'Policy method is missing' if Avo.configuration.raise_error_on_missing_policy

            return true
          end

          # Add the question mark if it's missing
          action = "#{action}?" unless action.end_with? "?"

          authorize user, record, action, **args
        end

        def apply_policy(user, model)
          return model if skip_authorization
          return model if user.nil?

          begin
            client.apply_policy! user, model
          rescue PolicyNotDefinedError => e
            return model unless Avo.configuration.raise_error_on_missing_policy

            raise e
          end
        end

        def skip_authorization
          Avo::App.license.lacks_with_trial :authorization
        end

        def authorized_methods(user, record)
          [:new, :edit, :update, :show, :destroy].map do |method|
            [method, authorize(user, record, Avo.configuration.authorization_methods[method])]
          end.to_h
        end

        def get_policy(user, record)
          client.policy user, record
        end

        def defined_methods(user, record, **args)
          client.policy!(user, record).methods
        rescue PolicyNotDefinedError => e
          return [] unless Avo.configuration.raise_error_on_missing_policy

          raise e
        rescue => error
          if args[:raise_exception] == false
            []
          else
            raise error
          end
        end
      end

      def initialize(user = nil, record = nil)
        @user = user
        @record = record
      end

      def authorize(action, **args)
        self.class.authorize(user, record, action, **args)
      end

      def set_record(record)
        @record = record

        self
      end

      def set_user(user)
        @user = user

        self
      end

      def authorize_action(action, **args)
        self.class.authorize_action(user, record, action, **args)
      end

      def apply_policy(model)
        self.class.apply_policy(user, model)
      end

      def defined_methods(model, **args)
        self.class.defined_methods(user, model, **args)
      end

      def has_method?(method, **args)
        defined_methods(record, **args).include? method.to_sym
      end
    end
  end
end
