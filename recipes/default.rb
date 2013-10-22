# Cookbook Name: jenkins-cf
# Recipe: default

include_recipe "user"
include_recipe "apt"
include_recipe "git"
include_recipe "git_user"
include_recipe "ssh_known_hosts"

%w{ curl libxslt-dev libxml2-dev libxml2-utils maven2 default-jdk build-essential libmysqlclient-dev libpq-dev libsqlite3-dev }.each { |package_name| package package_name }

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

 # %w{id_rsa }.each do |key|
 # 	template "#{jenkins_home}/.ssh/#{key}" do 
 # 		source key
 # 		user jenkins_user
 # 		# notifies :create, "ruby_block[store_server_ssh_pubkey]", :immediately
 # 	end
 # end

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
%w{ git scripttrigger rbenv parameterized-trigger copyartifact envinject ansicolor }.each do |plugin|
  jenkins_cli "install-plugin #{plugin}"
end

# Install Jenkins jobs
%w{ bosh-release-deploy bosh-release-upload cf-release-final-upload cf-release-final-deploy stemcell-watcher vcap-yeti bosh-bats }.each do |job_name|
	job_config = "/tmp/#{job_name}-config.xml"

	jenkins_job job_name do
	  action :nothing
	  config job_config
	end

	template job_config do
	  source "#{job_name}.xml"
	  variables :vars => node['jenkins_cf']
	  notifies :update, resources(:jenkins_job => job_name), :immediately
	  # notifies :build, resources(:jenkins_job => job_name), :immediately
	end	
end

jenkins_cli "safe-restart"
