class Util

  def dos2unixtime(time)
      unix_time = time.to_i/10000000-11644473600
      ruby_time = Time.at(unix_time)
      return ruby_time.strftime("%m/%d/%Y %H:%M:%S %Z")
  end

end
