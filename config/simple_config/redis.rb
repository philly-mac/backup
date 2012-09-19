SimpleConfig.for :application do

  group :redis do
    set :backup,   false
    set :user,     nil
    set :password  nil
  end

end
