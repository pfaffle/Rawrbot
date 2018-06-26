# Plugin which prints random quotes by Commander Riker from Star Trek TNG
class Riker
  include Cinch::Plugin

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(/riker/, method: :quote)

  def quote(m)
    reply = pick_random_line
    m.reply(reply)
  end

  def pick_random_line
    chosen_line = nil
    File.foreach('data/rikerquotes.txt').each_with_index do |line, number|
      chosen_line = line if rand < 1.0 / (number + 1)
    end
    chosen_line
  end
end
