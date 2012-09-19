module Backup
  module Providers
    class MongoDB

      def self.dump
        if AppConfig.mongodb.dump
          Backup::Providers::Log.log "Dumping Mongodb databases..."
          credentials = ''
          credentials = "-u #{AppConfig.mongodb.user}"     if AppConfig.mongodb.user
          credentials = "-p #{AppConfig.mongodb.password}" if AppConfig.mongodb.password
          system "#{AppConfig.mongodb.exec} #{credentials} --out - > #{path}/mongodb-database-#{Backup::Providers::Time.stamp}"
        end
      end

    end
  end
end