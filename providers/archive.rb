module Backup
  module Providers
    class Archive

      def self.name
        @@name ||= Backup::Backup.full? ?
          "backup-full-#{AppConfig.year}-#{AppConfig.week_number}" :
          "backup-incremental-#{AppConfig.year}-#{AppConfig.week_number}-#{AppConfig.day_number}"
      end

      def self.pack(path)
        Backup::Providers::Log.log("Packing the archive..")

        FileUtils.mkdir_p(AppConfig.destinations.archives)

        archive_name = "#{path}/#{name}"

        cmd = []
        cmd << "#{AppConfig.tar_exec} -cj #{path}"

        if AppConfig.openssl.use
          Backup::Providers::Log.log("Encrypting the archive..")
          cmd << "#{AppConfig.openssl.exec} des3 -salt -k #{AppConfig.openssl.passphrase}"
          archive_name << '.enc'
        end

        cmd << "split -b #{AppConfig.archive.backup_chunk_size}m -d - '#{archive_name}.tar.bz2-'"

        system cmd.join(' | ')
      end

      def self.unpack(path)

    end
  end
end