Dir.chdir(File.expand_path("../..", __FILE__))

require "rubygems"
require "bundler/setup"
require "fileutils"
require "yaml"

Bundler.require(:default)

File.open(File.expand_path("../../repositories.yml", __FILE__), "r") do |f|
  REPOSITORY_CONFIG = YAML.load(f.read)
end

def open_repository(name)
  config = config_for(name)
  fail ArgumentError, "#{name} not defined in repository map." unless config
  repo_url = config["git"]
  dir = File.expand_path("../../repos/#{name}.git", __FILE__)
  FileUtils.mkdir_p dir
  git = Git.bare(dir)

  begin
    git.show
    Dir.chdir(dir) do
      system("git fetch origin '*:*'")
    end
  rescue Git::GitExecuteError => e
    git = Git.clone(repo_url, dir, bare: true)
  end
  git
end

def config_for(name)
  REPOSITORY_CONFIG[name]
end
