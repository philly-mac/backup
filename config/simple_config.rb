SimpleConfig.for :application do
  #Change to suite your needs

  #Where you installed backup
  set :base, '/opt/backup'

  # Executables locations
  set :s3cmd_exec,           "/opt/s3cmd/s3cmd"
  set :rsync_exec,           "/usr/bin/rsync"
  set :tar_exec,             "/bin/tar"
  set :pg_dumpall_exec,      "/bin/pg_dumpall"
  set :mysqldump_exec,       "/usr/bin/mysqldump"
  set :mongodump_exec,       "/usr/bin/mongodump"

  # Where logs should be written to
  set :log_file_dir,  "#{base}/log"

  # Size in which to split the backup archives in megabytes
  set :backup_chunk_size, 100

  group :destinations do
    set :encrypt,     "#{base}/backups",
    set :archives,    "#{base}/archives"
    set :full,        "#{destinations[:encrypt]}/full",
    set :incremental, "#{destinations[:encrypt]}/incremental"
  end

  set :backup_type, 'full'

  set :year,        Time.now.strftime('%Y')
  set :week_number, Time.now.strftime('%V')
  set :day_number,  Time.now.strftime('%w')
    end

  set :excludes = [
    @destinations[:encrypt],
    @destinations[:archives]
  ]

  load File.join(APP_ROOT, 'config', "simple_config", "archive.rb"),      :if_exists? => true
  load File.join(APP_ROOT, 'config', "simple_config", "files.rb"),      :if_exists? => true
  load File.join(APP_ROOT, 'config', "simple_config", "mongo.rb"),      :if_exists? => true
  load File.join(APP_ROOT, 'config', "simple_config", "mysql.rb"),      :if_exists? => true
  load File.join(APP_ROOT, 'config', "simple_config", "openssl.rb"),    :if_exists? => true
  load File.join(APP_ROOT, 'config', "simple_config", "redis.rb"),      :if_exists? => true
  load File.join(APP_ROOT, 'config', "simple_config", "postgresql.rb"), :if_exists? => true
  load File.join(APP_ROOT, 'config', "simple_config", "amazon_s3.rb"),  :if_exists? => true

end
