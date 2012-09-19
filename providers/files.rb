module Backup
  module Providers
    class Files

      def self.dump
        if Backup::Backup.full?
          system "#{@rsync_exec} -Rav #{@excludes.map{|e| "--exclude=#{e}"}.join(' ')} #{@sources.join(' ')} #{@destinations[:full]}/")
        elsif Backup::Backup.incremental?
          @sources.each do |source|
            make_directory!("#{@destinations[:incremental]}#{source}")
            system "#{@rsync_exec} -Rav #{@excludes.map{|e| "--exclude=#{e}"}.join(' ')} --compare-dest=#{@destinations[:full]}/ #{source}/ #{@destinations[:incremental]}/"
          end
        end
      end
    end
  end
end