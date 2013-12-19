# Cookbook Name: jenkins-cf
# Recipe: default

include_recipe "user"
include_recipe "apt"
include_recipe "git"
include_recipe "git_user"
include_recipe "ssh_known_hosts"

def create_build_job(job_name, job_vars, job_template = nil)
	job_config = "/tmp/#{job_name}-config.xml"

	jenkins_job job_name do
	  action :nothing
	  config job_config
	end

	template job_config do
	  source job_template || "#{job_name}.xml"
	  variables :vars => job_vars
	  notifies :update, resources(:jenkins_job => job_name), :immediately
	  # notifies :build, resources(:jenkins_job => job_name), :immediately
	end	
end

%w{ curl libxslt-dev libxml2-dev libxml2-utils maven2 default-jdk build-essential libmysqlclient-dev libpq-dev libsqlite3-dev nova-console }.each { |package_name| package package_name }

node.set['jenkins']['server']['install_method'] = 'war'
node.set['jenkins']['server']['version'] = '1.536'

include_recipe "jenkins::server"
include_recipe "jenkins::proxy"

jenkins_user = node['jenkins']['server']['user']
jenkins_home = node['jenkins']['server']['home']

# Jenkins user modifications
user_account jenkins_user do
	home jenkins_home
  shell	'/bin/bash'
end

sudo jenkins_user do
	user jenkins_user
	nopasswd true
	runas 'ALL'
end

git_user jenkins_user do
  full_name   	node['jenkins_cf']['git']['user']
  email       	node['jenkins_cf']['git']['email']
  home					jenkins_home
end

# Drop SSH keys into Jenkins users so it can connect with git server 
directory "#{jenkins_home}/.ssh" do
	owner jenkins_user
	group jenkins_user
	recursive true
end

node['jenkins_cf']['git']['known_hosts'].each do |host|
  ssh_known_hosts_entry host
end

# Install update center json before attempting to install plugins 
directory "#{node['jenkins']['server']['home']}/updates/" do
  owner node['jenkins']['server']['user']
  group node['jenkins']['server']['user']
  action :create
end

execute "update jenkins update center" do
  command "wget http://updates.jenkins-ci.org/update-center.json -qO- | sed '1d;$d'  > #{node['jenkins']['server']['home']}/updates/default.json"
  user node['jenkins']['server']['user']
  group node['jenkins']['server']['user']
  creates "#{node['jenkins']['server']['home']}/updates/default.json"
end

# Install plugins
%w{ git scripttrigger rbenv parameterized-trigger copyartifact envinject ansicolor ws-cleanup }.each do |plugin|
  jenkins_cli "install-plugin #{plugin}"
end

# Install Jenkins jobs
%w{ bosh-outer-deploy bosh-inner-deploy bosh-release-upload cf-release-final-upload cf-release-final-deploy stemcell-watcher vcap-yeti bosh-bats }.each do |job_name|
	create_build_job(job_name, node['jenkins_cf'])
end

downstream_jobs = {
	:outer => "bosh-release-deploy",
	:inner => "cf-release-final-deploy"	
}

%w{ outer inner }.each do |bosh_layer|
	bosh_config = node['jenkins_cf']["#{bosh_layer}_bosh"]
	create_build_job("stemcell-#{bosh_layer}-upload", {
		:director_ip => bosh_config['director_ip'],
		:bosh_username => bosh_config['user'],
		:bosh_password => bosh_config['pass'],
		:downstream_jobs => downstream_jobs[bosh_layer.to_sym]
	}, "stemcell-uploader.xml")
end

jenkins_cli "safe-restart"