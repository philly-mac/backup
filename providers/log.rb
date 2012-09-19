module Backup
  module Providers
    class Log

      def self.log_file
        @@log_name ||= "#{AppConfig.log_file_dir}#{Backup::Providers::Archive.name}.log"
      end

      def self.create
        FileUtils.mkdir_p(AppConfig.log_file_dir)
        FileUtils.touch(log_file)
        system "> #{log_file}"
      end

    end
  end
end