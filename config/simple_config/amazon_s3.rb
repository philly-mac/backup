SimpleConfig.for :application do

  group :amazon_s3 do
    set :use,      false
    set :bucket,   "s3://my.bucket.com/"
  end

end
