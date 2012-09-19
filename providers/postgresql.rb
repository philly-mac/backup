module Backup
  module Providers
    class Postgresql

      def self.dump
        if AppConfig.postgresql.dump
          Backup::Providers::Log.log "Dumping Postgresql databases..."

          credentials = ''
          cmd         = ""

          credentials = "-U #{AppConfig.postgresql.user}"        if AppConfig.postgresql.user
          cmd << "PGPASSWORD=#{AppConfig.postgresql.password}; " if AppConfig.postgresql.password
          cmd << "#{AppConfig.postgresql.dumpall_exec} #{credentials} -c -w > #{path}/postgresql-database-#{Backup::Providers::Time.stamp}.sql"
          system cmd
        end
      end

    end
  end
end