require 'fileutils'

def log_file
  "/root/backup.log"
end

def passphrase_file_exists?
  File.exist?("/root/.PASSPHRASE")
end

def mount!
  if passphrase_file_exists?
    puts "Mounting..."
    cmd = []
    cmd << "mount -t ecryptfs"
    cmd << destinations[:encrypt]
    cmd << destinations[:encrypt]
    cmd << "-o ecryptfs_cipher=aes,ecryptfs_key_bytes=16,key=passphrase,ecryptfs_passthrough=n,passphrase_passwd_file=/root/.PASSPHRASE,ecryptfs_enable_filename_crypto=n"
    `#{cmd.join(' ')}`
  else
    puts "Please create a passphrase file"
    exit(1)
  end
end

def unmount!
  puts "Unmounting..."
  `umount #{destinations[:encrypt]}`
end

def mounted?
  system "df -t ecryptfs | grep \"#{destinations[:encrypt].gsub('/','\\/')}\" 2>&1 > /dev/null"
end

def dump_db(key)
  puts "Dumping database..."
  `pg_dumpall -U postgres -w > #{destinations[key]}/postgres-database-#{Time.now.strftime('%Y%m%d%H%M%S')}.sql >> #{log_file}`
end

def full?
  ARGV.first == 'full'
end

def inc?
  ARGV.first == 'inc'
end

def sources
   [
    "/var/www",
    "/etc",
    "/root",
    "/usr/local",
    "/home"
  ]
end

def excludes
  [
    '/root/backups',
    '/root/Backup',
    '/root/archives'
  ]
end

def destinations
  @destinations ||= {
    :encrypt  => '/root/backups',
    :archives => "/root/archives"
  }
end

def week_number
  Time.now.strftime('%V')
end

def day_number
  Time.now.strftime('%w')
end

def make_directory(key)
  path = key.is_a?(String) ? key : "#{destinations[key]}"
  if !File.exist?(path)
    puts "Creating #{path}"
    FileUtils.mkdir_p(path)
  end
end

def bucket
  "s3://linode.optomlocum.com/"
end

def clear_directory(key)
  path = "#{destinations[key]}/*"
  puts "Clearing #{path}.."
  `rm -rf #{path}`
end

def archive_name(key)
  key == :full ? "/backup-full-#{week_number}" : "/backup-inc-#{week_number}-#{day_number}"
end

def archive!(key)
  unless mounted?
    puts "Packing the archive.."
    make_directory(:archives)
    `tar -cjvf #{destinations[:archives]}/#{archive_name(key)}.tar.bz2 #{destinations[key]} >> #{log_file}`
  end
end

def transfer_to_s3(key)
  puts "Transfering to s3..."
  `/root/bin/s3cmd/s3cmd put #{destinations[:archives]}/#{archive_name(key)}.tar.bz2 #{bucket}`
end

def run(cmd)
  puts "Running #{cmd}..."
  `#{cmd}`
end

unless mounted?
  puts "Trying to mount.."
  mount!
end

destinations.merge!({
  :full        => "#{destinations[:encrypt]}/full",
  :incremental => "#{destinations[:encrypt]}/incremental"
})

if mounted?
  if full?
    puts "Full backup.."
    make_directory(:full)
    clear_directory(:full)
    run("rsync -Rav #{excludes.map{|e| "--exclude=#{e}"}.join(' ')} #{sources.join(' ')} #{destinations[:full]}/ > #{log_file}")
    dump_db(:full)
    unmount!
    archive!(:full)
    transfer_to_s3(:full)
  elsif inc?
    puts "Incremental backup.."
    make_directory(:incrental)
    clear_directory(:incremental)
    dump_db(:incremental)

    sources.each do |source|
      make_directory("#{destinations[:incremental]}#{source}")
      run("rsync -av --compare-dest=#{destinations[:full]}#{source}/ #{source}/ #{destinations[:incremental]}#{source}/ > #{log_file}")
    end

    unmount!
    archive(:incremental)
    transfer_to_s3(:incremental)
  end

else
  echo "Failed to mount"
end
