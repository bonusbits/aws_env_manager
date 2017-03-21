#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require 'pp'
require 'fileutils'

@script_version = '1.0.0'

# Parse Arguments/Options
@options = Hash.new

# Defaults Options
@options['debug_mode'] = false
@options['simplified_view'] = true

ARGV << '-h' if ARGV.empty?

options_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: aem.rb -c examples/us-west-2/client1/awsaccount1/dev/webapp1.yml [OPTIONS]'
  opts.separator ''
  opts.separator 'Options:'
  opts.on('-c', '--config FULLNAME', '(Required) Full Path to YAML Account Config') do |opt|
    @options['config_yaml'] = opt
  end
  opts.on('-l', '--list', '(Flag) List') do
    @options['list_configs'] = true
  end
  opts.on('-s', '--show', '(Flag) Show Current Env Vars') do
    @options['show_envs'] = true
  end
  opts.on('-d', '--debug', '(Flag) Enable Debug Logging') do
    @options['debug_mode'] = true
  end
  opts.on('-h', '--help', '(Flag) Show this message') do
    puts opts
    exit 0
  end
  opts.on('-v', '--version', '(Flag) Output Script Version') do
    puts "AWS Environment Manager Script v#{@script_version}"
    exit 0
  end
end
options_parser.parse(ARGV)

# Output Methods
def show_message(message, type = nil)
  case type
  when 'info'
    puts "INFO: #{message}"
  when 'results'
    puts "RESULTS: #{message}"
  when 'error'
    puts ''
    puts "ERROR: #{message}"
    puts ''
    raise
  else
    puts message
  end
end

def show_info(message)
  show_message(message, 'info')
end

def show_results(message)
  show_message(message, 'results')
end

def show_error(message)
  show_message(message, 'error')
end

def show_header
  system 'clear' unless system 'cls'
  show_message "AWS Environment Manager v#{@script_version}  |  Ruby v#{RUBY_VERSION}  |  by Levon Becker"
  show_message '--------------------------------------------------------------------------------'
  unless @options['config_yaml'].nil?
    show_message "YAML CONFIG:  (#{@options['config_yaml']})"
    show_message '--------------------------------------------------------------------------------'
  end
end

def show_sub_header(message)
  show_header
  show_message message
  show_message '--------------------------------------------------------------------------------'
  show_message ''
end

def show_footer
  show_sub_header 'COMPLETED!'
end

def load_config_yaml
  show_sub_header 'Parsing Configuration YAML'
  @yaml_config = YAML.load_file(File.open((@options['config_yaml']).to_s, 'r'))
  show_info 'Completed Configuration YAML Parsing'
end

def set_values
  show_sub_header 'SETTINGS VALUES'
  @options['config_yaml']
  ENV['AWS_REGION'] = @yaml_config['aws_region']
  ENV['AWS_PROFILE'] = @yaml_config['aws_profile']
  ENV['AWS_SSH_KEY_ID'] = @yaml_config['aws_ssh_key_id']
  ENV['AWS_SSH_KEY_PATH'] = @yaml_config['aws_ssh_key_path']
  ENV['AWS_VPC_ID'] = @yaml_config['aws_vpc_id']
  ENV['AWS_IAM_INSTANCE_PROFILE'] = @yaml_config['aws_iam_instance_profile']
  sg_count = 1
  @yaml_config['aws_security_groups'].each do |security_group|
    ENV["AWS_IAM_INSTANCE_PROFILE_#{sg_count}"] = security_group
    sg_count += 1
  end
  public_subnet_count = 1
  @yaml_config['aws_subnets_public'].each do |subnet|
    ENV["AWS_SUBNET_PUBLIC_#{public_subnet_count}"] = subnet
    public_subnet_count += 1
  end
  private_subnet_count = 1
  @yaml_config['aws_subnets_private'].each do |subnet|
    ENV["AWS_SUBNET_PRIVATE_#{private_subnet_count}"] = subnet
    private_subnet_count += 1
  end
  ENV['AWS_PUBLIC_IP'] = @yaml_config['aws_public_ip'].to_s
end

def show_values
  show_sub_header 'CURRENT VALUES'
  values = [
    "AWS_REGION:               #{ENV['AWS_REGION']}",
    "AWS_PROFILE:              #{ENV['AWS_PROFILE']}",
    "AWS_SSH_KEY_ID:           #{ENV['AWS_SSH_KEY_ID']}",
    "AWS_SSH_KEY_PATH:         #{ENV['AWS_SSH_KEY_PATH']}",
    "AWS_VPC_ID:               #{ENV['AWS_VPC_ID']}",
    "AWS_IAM_INSTANCE_PROFILE: #{ENV['AWS_IAM_INSTANCE_PROFILE']}",
    "AWS_SECURITY_GROUP_1:     #{ENV['AWS_SECURITY_GROUP_1']}",
    "AWS_PUBLIC_IP:            #{ENV['AWS_PUBLIC_IP']}"
  ]
  values.each do |message|
    show_message message
  end
end

def run
  if @options['show_envs']
    show_values
  else
    show_header
    load_config_yaml
    set_values
    show_values
  end
  # show_footer
end

# Run
run
