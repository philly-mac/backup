module Backup
  module Providers
    class Time

      def self.stamp
        Time.now.strftime('%Y%m%d%H%M%S')
      end

    end
  end
end