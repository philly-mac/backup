require 'fileutils'

# Requirements
# Ecryptfs utils - https://launchpad.net/ecryptfs
# Rsync          - http://rsync.samba.org/
# s3cmd          - https://github.com/s3tools/s3cmd
# tar            - http://www.gnu.org/software/tar/
# rm             - http://pubs.opengroup.org/onlinepubs/9699919799/utilities/rm.html

# Optional

# Postgres       - http://www.postgresql.org/

# Follow the individual instructions for each of the tools on how to set them up properly

# Hint! for ecryptfs you will have to create a file which has the format
# passwd=THE_PASSWORD_YOU_WANT_TO_USE_TO_ENCRYPT

# I also suggest that you run the ecrypt mount at least once manually because it will ask you to
# store the options the first time you run. Just answer yes, and then when you run this tool it wont
# seem to freeze.

##################################
# Config

s3cmd_exec           = "/root/bin/s3cmd/s3cmd"
rsync_exec           = "/usr/bin/rsync"
tar_exec             = "/bin/tar"
rm_exec              = "/bin/rm"

bucket               = "s3://linode.optomlocum.com/"
ecrypt_password_file = "/root/.PASSPHRASE"
ecrypt_options       = "-o ecryptfs_cipher=aes,ecryptfs_key_bytes=16,key=passphrase,ecryptfs_passthrough=n,passphrase_passwd_file=#{ecrypt_password_file},ecryptfs_enable_filename_crypto=n"
log_file_dir         = "/root/"

destinations         ||= {
  :encrypt  => '/root/backups',
  :archives => "/root/archives"
}

destinations.merge!({
  :full        => "#{destinations[:encrypt]}/full",
  :incremental => "#{destinations[:encrypt]}/incremental"
})

# What to backup
sources = [
  "/var/www",
  "/etc",
  "/root",
  "/usr/local",
  "/home"
]

# What to exclude from backups
excludes = [
  destinations[:encrypt],
  destinations[:archives]
] + [
  # Add your custom excludes here
  '/root/Backup',
]

# End config
##################################

def log_file
  @log_name ||= "#{archive_name}.log"
end

def create_log_file
  make_directory(log_file_dir)
  run("touch #{log_file}")
end

def run(cmd, exit_check = false)
  cmd << " >> #{log_file}"
  puts "Running #{cmd}..."
  exit_check ? system(cmd) : `#{cmd}`
end

def passphrase_file_exists?
  File.exist?(ecrypt_password_file)
end

def mount!
  if passphrase_file_exists?
    puts "Mounting..."
    cmd = []
    cmd << "mount -t ecryptfs"
    cmd << destinations[:encrypt]
    cmd << destinations[:encrypt]
    cmd << ecrypt_options
    run(cmd.join(' '))
  else
    puts "Please create a passphrase file"
    exit(1)
  end
end

def unmount!
  puts "Unmounting..."
  run("umount #{destinations[:encrypt]}")
end

def mounted?
  run("df -t ecryptfs | grep \"#{destinations[:encrypt].gsub('/','\\/')}\" 2>&1 > /dev/null", true)
end

def dump_db(key)
  puts "Dumping database..."
  run("pg_dumpall -U postgres -w > #{destinations[key]}/postgres-database-#{Time.now.strftime('%Y%m%d%H%M%S')}.sql")
end

def full?
  ARGV.first == 'full'
end

def inc?
  ARGV.first == 'inc'
end

def week_number
  Time.now.strftime('%V')
end

def day_number
  Time.now.strftime('%w')
end

def make_directory(key)
  path = key.is_a?(String) ? key : "#{destinations[key]}"
  unless File.exist?(path)
    puts "Creating #{path}"
    FileUtils.mkdir_p(path)
  end
end

def clear_directory(key)
  path = "#{destinations[key]}/*"
  puts "Clearing #{path}.."
  run("#{rm_exec} -rf #{path}")
end

def archive_name(key)
  key == :full ? "/backup-full-#{week_number}" : "/backup-inc-#{week_number}-#{day_number}"
end

def archive!(key)
  unless mounted?
    puts "Packing the archive.."
    make_directory(:archives)
    run("#{tar_exec} -cjvf #{destinations[:archives]}/#{archive_name(key)}.tar.bz2 #{destinations[key]}")
  end
end

def transfer_to_s3(key)
  puts "Transfering to s3..."
  run "#{s3cmd_exec} put #{destinations[:archives]}/#{archive_name(key)}.tar.bz2 #{bucket}"
end


# Backup
if full?
  puts "Full backup.."

  mount! unless mounted?

  if mounted?
    create_log_file
    make_directory(:full)
    clear_directory(:full)
    run("rsync -Rav #{excludes.map{|e| "--exclude=#{e}"}.join(' ')} #{sources.join(' ')} #{destinations[:full]}/")
    dump_db(:full)
    unmount!
    archive!(:full)
    transfer_to_s3(:full)
  end
elsif inc?
  puts "Incremental backup.."

  mount! unless mounted?

  if mounted?
    create_log_file
    make_directory(:incrental)
    clear_directory(:incremental)

    sources.each do |source|
      make_directory("#{destinations[:incremental]}#{source}")
      run("rsync -av --compare-dest=#{destinations[:full]}#{source}/ #{source}/ #{destinations[:incremental]}#{source}/")
    end

    dump_db(:incremental)
    unmount!
    archive(:incremental)
    transfer_to_s3(:incremental)
  end
else
  puts "Failed to mount"
end

puts "Week Number #{week_number}"
puts "Day Number #{day_number}"