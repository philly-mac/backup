SimpleConfig.for :application do

  group :archive do
    set :exec,             '/bin/tar'
    set :backup_chunk_size, 100
  end

end
