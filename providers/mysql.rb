module Backup
  module Providers
    class MySQL

      def self.dump
        if AppConfig.mysql.dump
          Backup::Providers::Log.log "Dumping Mysql databases..."
          credentials = ''
          credentials = "-u #{AppConfig.mysql.user}"     if AppConfig.mysql.user
          credentials = "-p #{AppConfig.mysql.password}" if AppConfig.mysql.password
          system "#{AppConfig.mysql.exec} #{credentials} --all-databases > #{path}/mysql-database-#{Backup::Providers::Time.stamp}.sql"
        end
      end

    end
  end
end