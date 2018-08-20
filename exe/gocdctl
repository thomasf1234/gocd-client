#!/usr/bin/env ruby

###################### Requires ################################

require 'optparse'
require "bundler/setup"
require "gocd-client"

###################### Constants ################################


NEWLINE = $/
OPTION_MAPPING = {
    "--help" => :help,
    "-h" => :help,
    "--pipeline-path" => :pipeline_path,
    "--stage-name" => :stage_name,
    "--job-name" => :job_name,
    "--source-path" => :source_path,
    "--destination" => :destination
}

options = {}

###################### OptionParsers ################################

healthcheck_option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} healthcheck [options]"

  opts.on("-h", "--help", "Displays this help.") do
    options[:help] = true
    puts opts
  end
end

fetch_artifact_option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} fetch_artifact [options]"
  
  opts.on("--pipeline-path=pipeline_path", "The pipeline path.") do |pipeline_path|
    options[:pipeline_path] = pipeline_path
  end

  opts.on("--stage-name=stage_name", "The stage path.") do |stage_name|
    options[:stage_name] = stage_name
  end

  opts.on("--job-name=job_name", "The job path.") do |job_name|
    options[:job_name] = job_name
  end

  opts.on("--source-path=source_path", "The artifact source path.") do |source_path|
    options[:source_path] = source_path
  end

  opts.on("--destination=destination", "The destination path to save the downloaded artifact.") do |destination|
    options[:destination] = destination
  end

  opts.on("-h", "--help", "Displays this help.") do
    options[:help] = true
    puts opts
  end
end

###################### Subcommands ################################

subcommands = {
  "healthcheck" => {
    "description" => "check if gocd server is running",
    "required_options" => [],
    "option_parser" => healthcheck_option_parser
  },

  "fetch_artifact" => {
    "description" => "Fetch an artifact from a pipeline path",
    "required_options" => ["--pipeline-path", "--stage-name", "--job-name", "--source-path", "--destination"],
    "option_parser" => fetch_artifact_option_parser
  }
}
  
#help message
longest_subcommand_key = subcommands.keys.max_by(&:length)
help_message = ""
help_message += "Commonly used command are:"
help_message += NEWLINE
subcommands.each do |subcommand, hash|
  help_message += "   %-#{longest_subcommand_key.length+5}s %s" % [subcommand, hash["description"]]
  help_message += NEWLINE
end
help_message += NEWLINE
help_message += "See '#{__FILE__} COMMAND --help' for more information on a specific command."


global_option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options] [subcommand [options]]"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.separator ""
  opts.separator help_message
end

global_option_parser.order!
command = ARGV.shift
VALID_COMMANDS = subcommands.keys
if !VALID_COMMANDS.include?(command)
  raise ArgumentError.new("Valid commands include #{VALID_COMMANDS}")
end

option_parser = subcommands[command]["option_parser"]
option_parser.order!

gocd = GocdClient::Service.new(ENV['GO_SERVER_URL'], ENV['GO_SERVER_USER'], ENV['GO_SERVER_PWD'])

if options.has_key?(:help) && options[:help] == true
  #
else
  subcommands[command]["required_options"].each do |required_option|
    required_option_key = OPTION_MAPPING[required_option]
    if !options.include?(required_option_key)
      raise ArgumentError.new("options must include #{required_option}")
    end
  end
  
  case command
    when "healthcheck"
      puts gocd.healthcheck
    when "fetch_artifact"
      #GO_SERVER_URL=https://goserver GO_SERVER_USER=user GO_SERVER_PWD=password ./bin/gocdctl.rb fetch_artifact --pipeline-path BuildPipeline/Test-UAT/Test-STG --stage-name stage --job-name job --source-path path/to/artifact.tar.gz --destination /tmp/artifact.tar.gz
      gocd.fetch_artifact(options[:pipeline_path], options[:stage_name], options[:job_name], options[:source_path], options[:destination])
    else
      raise ArgumentError.new("unsupported command #{command}")
  end
end

