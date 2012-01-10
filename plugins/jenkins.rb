module BotPlugins
  class Jenkins
    include Cinch::Plugin

    match /build\s?(.+)?/
  
    help "Interfaces with the Jenkins build server"
    
    def execute(m, params)
      config = HelperLib::SharedObject.instance(:config)
      return if config.plugins.jenkins.nil?
      
      base_addr = "http://#{config.plugins.jenkins.base_address}"
      options = {:basic_auth => {:username => config.plugins.jenkins.username, :password => config.plugins.jenkins.password}}
      
      case params
      when /start (.*)/
        match_data = params.match(/start (.*)/)
        if match_data.length > 0
          job = match_data[1]
          job_key = job.downcase.gsub(/\s/,"_").gsub(/\W/,"").to_sym
          build_key = ""
          build_key = config.plugins.jenkins.keys.send(job.downcase) unless (config.methods - Object.methods - OpenStruct.instance_methods).include?(job_key)          
          
          response = HTTParty.get("#{base_addr}/job/#{job}/build?token=#{build_key}&cause=IRC+command+from+#{m.user.nick}", options)
          m.reply("Kicking off build") if response.code.eql?(200)
        end
      else
        # just show an update
        response = HTTParty.get("#{base_addr}/api/json", options)
        response["jobs"].each do |job|
          job_status = HTTParty.get("#{job["url"]}/api/json", options)
          last_success = job_status["lastSuccessfulBuild"].nil? ? nil : job_status["lastSuccessfulBuild"]["number"]
          last_fail = job_status["lastUnsuccessfulBuild"].nil? ? nil : job_status["lastUnsuccessfulBuild"]["number"]
          current_build = job_status["lastBuild"].nil? ? nil : job_status["lastBuild"]["number"]
          status = current_build.eql?(last_success) ? "stable" : "unknown"
          status = "failing" if (current_build.eql?(last_fail) || last_fail > last_success)
          run_time = ""
          in_progress = false
          if (job_status["lastBuild"] && job_status["lastBuild"]["url"])
            last_run = HTTParty.get("#{job_status["lastBuild"]["url"]}/api/json", options)
            run_time = "Executed at #{Time.at(last_run["timestamp"]/1000).to_s}"
            in_progress = last_run["building"]
          end
          m.reply("Job '#{job_status["name"]}' is #{status}#{in_progress ? " (in progress)" : ""}")
          m.reply("   #{run_time}") if run_time.length > 0
          m.reply("   #{job_status["healthReport"].last["description"]}")
        end
      end
    end
  end
end
