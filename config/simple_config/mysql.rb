SimpleConfig.for :application do

  group :mysql do
    set :backup,   false
    set :user,     nil
    set :password  nil
  end

end
