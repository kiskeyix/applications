require 'yaml'

config = {}
config_file = "#{File.dirname(__FILE__)}/config.yml"
if File.exists? config_file
    config = YAML::load_file config_file
end

# sanity default:
config['tmpdir'] = "/var/tmp" unless config.key? "tmpdir"

task :default do |t|
    sh "rake -D --silent"
end

# import all *.rake tasks from "tasks" dir
Dir["tasks/*.rake"].sort.each do |ext|
    import ext
end

desc "Runs all cleaning tasks"
task :clean => [:clean_tmp] do |t|
end

desc "Removes all our temporary files in #{config['tmpdir']}"
task :clean_tmp do |t|
    FileUtils.rm_f Dir.glob("#{config['tmpdir']}/*")
end

# adds "rake test" use TEST=file to run only a single test
require 'rake/testtask'
Rake::TestTask.new do |t|
    t.libs << "t"
    t.test_files = Dir.glob("t/test_*.rb")
end
