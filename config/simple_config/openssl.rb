SimpleConfig.for :application do

  group :openssl do
    set :use,        false
    set :passphrase, nil
  end

end
