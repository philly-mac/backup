SimpleConfig.for :application do

  group :files do
    set :backup,   false
    set :sources,  [
      "/var/www",
      "/etc",
      "/root",
      "/usr/local",
      "/home"
    ]
  end

end
