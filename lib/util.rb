# Assorted utility methods
class Util
  def dos2unixtime(time)
    unix_time = time.to_i / 10_000_000 - 11_644_473_600
    ruby_time = Time.at(unix_time)
    ruby_time.strftime('%m/%d/%Y %H:%M:%S %Z')
  end
end
