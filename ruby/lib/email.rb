# Class that represents an email resource from the VerticalResponse API.
# It has the ability to make REST calls to the API, as well as to wrap
# the email objects we get as response.
#
# NOTE: This class does not necessarily include all the available methods
# the API has for the email resource. You can consider this an initial approach
# for an object oriented solution that you can expand according to your needs.

require_relative 'client'
require_relative 'list'

module VerticalResponse
  module API
    class Email < Client
      class << self
        # Base URI for the Email resource
        def base_uri(*args)
          @base_uri ||= File.join(super.to_s, 'messages', 'emails')
        end

        # Overwrite from parent class since it's a special type of
        # resource name (with messages at the beginning)
        def resource_name
          'messages/emails'
        end

        # The Email API does not support the 'all' method on its own for now.
        # To get all emails we need to do it through the Message API
        def all(options = {})
          Message.all(options.merge({ :message_type => MESSAGE_TYPE }))
        end
      end

      MESSAGE_TYPE = 'email'

      def initialize(*args)
        super
        @list_class = self.class.class_for_resource(List, id)
      end

      # Returns all the lists this email is targeted to
      def lists(options = {})
        @list_class.all(options)
      end

      def test_launch(params = {})
        Response.new self.class.post(
          self.class.resource_uri(id, 'test'),
          self.class.build_params(params)
        )
      end

      # Launches an email and return the response object
      def launch(params = {})
        # Supports receiving an array of List objects (Object Oriented)
        lists = params.delete(:lists)
        if lists
          params[:list_ids] ||= []
          params[:list_ids] += lists.map do |list|
            list.respond_to?(:id) ? list.id : list.to_i
          end
          # Remove duplicate IDs, if any
          params[:list_ids].uniq!
        end

        Response.new self.class.post(
          self.class.resource_uri(id),
          self.class.build_params(params)
        )
      end

      def unschedule
        Response.new self.class.post(
          self.class.resource_uri(id, 'unschedule')
        )
      end
    end
  end
end
