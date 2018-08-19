require 'net/http'
require 'json'
require 'openssl'

module GocdClient
  class Service

    attr_reader :url

    def initialize(url, username, password)
      @url = url
      @username = username
      @password = password
    end

    ############### Server Health ###############

    def healthcheck
      if version >= '17.11.0'
        healthcheck_json = get('/go/api/v1/health', {"Accept" => "application/vnd.go.cd.v1+json"}).body
        JSON.parse(healthcheck_json)
      else
        raise NotImplementedError.new
      end
    end

    ############### Agents #####################

    def agents
      if version >= '15.2.0'
        agents_json = JSON.parse(get('/go/api/agents', {"Accept" => "application/vnd.go.cd.v4+json"}).body)
        agents_json['_embedded']['agents'].map do |agent_json|
          Models::Agent.new(agent_json)
        end
      else
        raise NotImplementedError.new
      end
    end

    def agent(uuid)
      if version >= '15.2.0'
        agent_json = JSON.parse(get("/go/api/agents/#{uuid}", {"Accept" => "application/vnd.go.cd.v4+json"}).body)
        Models::Agent.new(agent_json)
      else
        raise NotImplementedError.new
      end
    end

    ############### Agent Health ###############

    ############### Users ######################

    ############### Current User ###############

    ############### Notification Fileters ######

    ############### Materials ##################

    ############### Backups ####################

    ############### Pipeline Groups ############

    ############### Artifacts ##################

    def artifacts(pipeline_name, pipeline_counter, stage_name, stage_counter, job_name)
      if version > '14.3.0'
        JSON.parse(get("/go/files/#{pipeline_name}/#{pipeline_counter}/#{stage_name}/#{stage_counter}/#{job_name}.json", {'Accept' => 'application/json'}).body)
      else
        raise NotImplementedError.new
      end
    end

    def artifact_download(pipeline_name, pipeline_counter, stage_name, stage_counter, job_name, source_path, destination)
      endpoint = File.join("/go/files/#{pipeline_name}/#{pipeline_counter}/#{stage_name}/#{stage_counter}/#{job_name}", source_path)

      connect do |http|
        request = Net::HTTP::Get.new(endpoint)
        request.basic_auth(@username, @password)
        http.request(request) do |response|
          File.open(destination, 'w') do |io|
            response.read_body do |chunk|
              io.write(chunk)
            end
          end
        end
      end
    end

    ############### Pipelines ##################

    def pipeline(pipeline_name, pipeline_counter)
      pipeline_json = get("/go/api/pipelines/#{pipeline_name}/instance/#{pipeline_counter}", {'Accept' => "application/json"}).body
      Models::Pipeline.new(JSON.parse(pipeline_json))
    end

    def pipeline_history(pipeline_name, offset=0)
      history_json = get("/go/api/pipelines/#{pipeline_name}/history/#{offset}", {'Accept' => "application/json"}).body
      Models::PipelineHistory.new(JSON.parse(history_json))
    end

    ############### Stages #####################

    def stage(pipeline_name, stage_name, pipeline_counter, stage_counter)
      stage_json = get("/go/api/stages/#{pipeline_name}/#{stage_name}/instance/#{pipeline_counter}/#{stage_counter}").body
      Models::Stage.new(stage_json)
    end

    ############### Version ####################

    def version
      @version ||= Models::Version.new(JSON.parse(get('/go/api/version', {"Accept" => "application/vnd.go.cd.v1+json"}).body))
    end


    ############### Extension ##################

    #fetch_artifact('CP-GenerateCashReportJob/TestJobDeploy-UAT/TestJobDeploy-STG', 'buildTestPackage', 'buildTestPackage', 'GenerateCashReport-linux-x64.tar.gz', '/tmp/GenerateCashReport-linux-x64-4.tar.gz')
    def fetch_artifact(pipeline_path, stage_name, job_name, source_path, destination)
      pipeline_names_descending = pipeline_path.split('/').reverse

      #get parent pipeline
      parent_pipeline_name = pipeline_names_descending.shift
      parent_pipeline = pipeline_latest_passed(parent_pipeline_name)
      parent_pipeline_counter = parent_pipeline.counter
      parent_stage_name = nil 
      parent_stage_counter = nil

      pipeline_names_descending.each do |pipeline_name|
        material_revision = parent_pipeline.build_cause['material_revisions'].detect do |_material_revision| 
          _material_revision['material']['type'] == 'Pipeline' && _material_revision['material']['description'] == pipeline_name 
        end

        revision = material_revision['modifications'].first['revision']
        parent_pipeline_name, parent_pipeline_counter, parent_stage_name, parent_stage_counter = revision.split('/')
        parent_pipeline = pipeline(parent_pipeline_name, parent_pipeline_counter)
      end

      parent_pipeline_stage = parent_pipeline.stages.detect {|stage| stage.name == stage_name}
      parent_pipeline_counter = parent_pipeline.counter
      parent_stage_name = parent_pipeline_stage.name 
      parent_stage_counter = parent_pipeline_stage.counter

      artifact_download(parent_pipeline_name, parent_pipeline_counter, parent_stage_name, parent_stage_counter, job_name, source_path, destination)
    end

    def pipeline_latest_passed(pipeline_name)
      offset = 0 
      found = nil

      until found do 
        history = pipeline_history(pipeline_name, offset)
        break if history.pipelines.empty?
        pipeline_descending = history.pipelines.sort_by(&:counter).reverse
        
        pipeline_descending.each do |pipeline|
          if pipeline.stages.all?(&:passed?)
            found = pipeline
            break
          end
        end

        offset += 10
      end

      found.nil? ? nil : found
    end

    ############### Private ##################

    private
    def get(endpoint, headers={})
      connect do |http|
        request = Net::HTTP::Get.new(endpoint, headers)
        request.basic_auth(@username, @password)
        http.request(request)
      end
    end

    def connect
      http = get_http(@url)
      response = yield(http)

      if response.code.match(/2\d{2}/)
        response
      else
        raise("Error response code #{response.code}")
      end
    end

    def get_http(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.kind_of?(URI::HTTPS)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        http.use_ssl = false
      end 

      http.read_timeout = @read_timeout
      http
    end
  end
end

