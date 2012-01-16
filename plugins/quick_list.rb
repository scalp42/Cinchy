require 'pathname'
require 'uri'
require 'find'
module BotPlugins
  class QuickList
    include Cinch::Plugin

    match 'list'
  
    help "Shows available files to be played via VLC"
    
    def execute(m)
        config = HelperLib::SharedObject.instance(:config)
        start_path = config.plugins.music_path
      
        m.reply("Available files in: #{start_path}")
        Find.find(start_path) do |file_path|
          m.reply("#{file_path}")
        end
      
    end
  end
end
