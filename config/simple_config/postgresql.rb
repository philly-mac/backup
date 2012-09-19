SimpleConfig.for :application do

  group :postgresql do
    set :backup,   false
    set :user,     nil
    set :password, nil
  end

end
