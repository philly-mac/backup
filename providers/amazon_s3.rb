module Backup
  module Providers
    class AmazonS3

      def self.transfer
        Backup::Providers::Log.log "Transfering to s3..."
        system "#{AppConfig.amazon_s3.exec} put #{path}/#{Backup::Providers::Archive.name}.tar.bz2* #{AppConfig.amazon_s3.bucket}"
        system "#{AppConfig.amazon_s3.exec} ls #{AppConfig.amazon_s3.bucket}"
      end

    end
  end
end