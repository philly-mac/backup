require 'fileutils'

# Requirements
# openssl        -
# Rsync          - http://rsync.samba.org/
# s3cmd          - https://github.com/s3tools/s3cmd
# tar            - http://www.gnu.org/software/tar/
# rm             - http://pubs.opengroup.org/onlinepubs/9699919799/utilities/rm.html
# split
# Amazon s3      - http://aws.amazon.com/s3/

# Optional

# Postgres       - http://www.postgresql.org/

# Follow the individual instructions for each of the tools on how to set them up properly

##################################
# Config

@base                 = '/opt/backup'
@s3cmd_exec           = "#{@base}/bin/s3cmd/s3cmd"
@rsync_exec           = "/usr/bin/rsync"
@tar_exec             = "/bin/tar"
@rm_exec              = "/bin/rm"

@bucket               = "s3://linode.optomlocum.com/"

# File with password used to encrypt
@ecrypt_password_file = "#{@base}/config/PASSPHRASE"
@log_file_dir         = "#{@base}/log"

@destinations         ||= {
  :encrypt  => '#{@base}/backups',
  :archives => "#{@base}/archives"
}

@destinations.merge!({
  :full        => "#{@destinations[:encrypt]}/full",
  :incremental => "#{@destinations[:encrypt]}/incremental"
})

# What to backup
@sources = [
  "/var/www",
  "/etc",
  "/root",
  "/usr/local",
  "/home"
]

# What to exclude from backups
@excludes = [
  @destinations[:encrypt],
  @destinations[:archives]
] + [
  # Add your custom excludes here
]

# End config
##################################

def log_file
  key = full? ? :full : :incremental
  @log_name ||= "#{@log_file_dir}#{archive_name(key)}.log"
end

def create_log_file!
  make_directory!(@log_file_dir)
  run!("touch #{log_file}")
  run!("> #{log_file}")
end

def run!(cmd, log = true, exit_check = false)
  cmd << " >> #{log_file}" if log
  puts "Running #{cmd}..."
  exit_check ? system(cmd) : `#{cmd}`
end

def passphrase_file_exists?
  File.exist?(@ecrypt_password_file)
end

def dump_db!(key)
  # TODO: check postgres exists
  puts "Dumping database..."
  run!("pg_dumpall -U postgres -w > #{@destinations[key]}/postgres-database-#{Time.now.strftime('%Y%m%d%H%M%S')}.sql", false)
end

def full?
  @full ||= ARGV.first == 'full'
end

def inc?
  @inc ||= ARGV.first == 'inc'
end

def year
  @year ||= Time.now.strftime('%Y')
end

def week_number
  @week_number ||= Time.now.strftime('%V')
end

def day_number
  @day_number ||= Time.now.strftime('%w')
end

def archive_name
  full? ? "/backup-full-#{year}-#{week_number}" : "/backup-inc-#{year}-#{week_number}-#{day_number}"
end

def make_directory!(key)
  path = key.is_a?(String) ? key : "#{@destinations[key]}"
  unless File.exist?(path)
    puts "Creating #{path}"
    FileUtils.mkdir_p(path)
  end
end

def clear_directory!(key)
  path = "#{@destinations[key]}/*"
  puts "Clearing #{path}.."
  run!("#{@rm_exec} -rf #{path}")
end

def archive!(key)
  puts "Packing the archive.."
  make_directory!(:archives)
  run!("#{@tar_exec} -cj #{@destinations[key]} | openssl des3 -salt -k `cat #{@ecrypt_password_file}` | split -b 100m -d - '#{archive_name}.tar.bz2-'", false)
end

def transfer_to_s3!(key)
  puts "Transfering to s3..."
  run!("#{@s3cmd_exec} put #{@destinations[:archives]}/#{archive_name}.tar.bz2* #{@bucket}")
  run!("#{@s3cmd_exec} -ls #{@bucket}")
end

# Backup
if full?
  puts "Full backup.."
  create_log_file!
  make_directory!(:full)
  clear_directory!(:full)
  run!("#{@rsync_exec} -Rav #{@excludes.map{|e| "--exclude=#{e}"}.join(' ')} #{@sources.join(' ')} #{@destinations[:full]}/")
  dump_db!(:full)
  archive!(:full)
  transfer_to_s3!(:full)
elsif inc?
  puts "Incremental backup.."
  create_log_file!
  make_directory!(:incremental)
  clear_directory!(:incremental)

  @sources.each do |source|
    make_directory!("#{@destinations[:incremental]}#{source}")
    run!("#{@rsync_exec} -Rav #{@excludes.map{|e| "--exclude=#{e}"}.join(' ')} --compare-dest=#{@destinations[:full]}/ #{source}/ #{@destinations[:incremental]}/")
  end

  dump_db!(:incremental)
  archive!(:incremental)
  transfer_to_s3!(:incremental)
end

puts "Year #{year}"
puts "Week Number #{week_number}"
puts "Day Number #{day_number}"
