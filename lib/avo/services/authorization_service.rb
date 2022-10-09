module Avo
  module Services
    class AuthorizationService
      attr_accessor :user
      attr_accessor :record

      class << self
        def client
          Avo::Services::AuthorizationClients::PunditClient.new
        end

        def authorize(user, record, action, policy_class: nil, **args)
          return true if skip_authorization
          return true if user.nil?
          # This clause was present but also NoPolicyError was being rescued
          # Unsure what the intent was, but removing this clause breaks tests
          # in after_create_update_path_spec.rb
          # Is the NoPolicyError rescue for policies that call other policies?
          return true unless client.policy(user, record).present?

          client.authorize user, record, action, policy_class: policy_class

          true
        rescue NoPolicyError => error
          return false unless Avo.configuration.raise_error_on_missing_policy

          # Should this respect a `raise_exception` argument?
          raise error
        rescue => error
          if args[:raise_exception] == false
            false
          else
            raise error
          end
        end

        def authorize_action(user, record, action, policy_class: nil, **args)
          action = Avo.configuration.authorization_methods.stringify_keys[action.to_s] || action

          # If no action passed we should raise error if the user wants that.
          # If not, just allow it.
          if action.nil?
            raise NoPolicyError.new "Policy method is missing" if Avo.configuration.raise_error_on_missing_policy

            return true
          end

          # Add the question mark if it's missing
          action = "#{action}?" unless action.end_with? "?"
          authorize(user, record, action, policy_class: policy_class, **args)
        end

        def apply_policy(user, model, policy_class: nil)
          return model if skip_authorization || user.nil?

          client.apply_policy(user, model, policy_class: policy_class)
        rescue NoPolicyError => error
          return model unless Avo.configuration.raise_error_on_missing_policy

          raise error
        end

        def skip_authorization
          Avo::App.license.lacks_with_trial :authorization
        end

        def authorized_methods(user, record)
          [:new, :edit, :update, :show, :destroy].map do |method|
            [method, authorize(user, record, Avo.configuration.authorization_methods[method])]
          end.to_h
        end

        def defined_methods(user, record, policy_class: nil, **args)
          return client.policy!(user, record).methods if policy_class.nil?

          # I'm aware this will not raise a Pundit error.
          # Should the policy not exist, it will however raise an uninitialized constant error, which is probably what we want when specifying a custom policy
          policy_class.new(user, record).methods
        rescue NoPolicyError => error
          return [] unless Avo.configuration.raise_error_on_missing_policy

          raise error
        rescue => error
          if args[:raise_exception] == false
            []
          else
            raise error
          end
        end
      end

      def initialize(user = nil, record = nil, policy_class: nil)
        @user = user
        @record = record
        @policy_class = policy_class || self.class.client.policy(user, record)&.class
      end

      def authorize(action, **args)
        self.class.authorize(user, record, action, policy_class: @policy_class, **args)
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
        self.class.authorize_action(user, record, action, policy_class: @policy_class, **args)
      end

      def apply_policy(model)
        self.class.apply_policy(user, model, policy_class: @policy_class)
      end

      def defined_methods(model, **args)
        self.class.defined_methods(user, model, policy_class: @policy_class, **args)
      end

      def has_method?(method, **args)
        defined_methods(record, **args).include? method.to_sym
      end
    end
  end
end
