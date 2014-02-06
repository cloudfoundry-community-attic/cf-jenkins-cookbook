# Basic Jenkins install

include_recipe 'user'
include_recipe 'apt'
include_recipe 'git'
include_recipe 'git_user'
#include_recipe 'ssh_known_hosts'

%w{ vim
    curl 
    libcurl4-openssl-dev 
    libxslt-dev 
    libxml2-dev 
    libxml2-utils 
    maven2 
    default-jdk 
    build-essential 
    libmysqlclient-dev 
    libpq-dev 
    libsqlite3-dev 
    genisoimage
    nova-console 
    debootstrap 
    kpartx
    golang-go
    bzr }.each { |package_name| package package_name }

node.set['jenkins']['master']['install_method'] = 'war'
node.set['jenkins']['master']['version'] = '1.548'

include_recipe 'jenkins::java'
include_recipe 'jenkins::master'

jenkins_user = node['jenkins']['master']['user']
jenkins_home = node['jenkins']['master']['home']

# Jenkins user modifications
user_account jenkins_user do
  home jenkins_home
  shell '/bin/bash'
end

sudo jenkins_user do
  user jenkins_user
  nopasswd true
  runas 'ALL'
end

git_user jenkins_user do
  full_name     node['jenkins_cf']['git']['user']
  email         node['jenkins_cf']['git']['email']
  home          jenkins_home
end

# Jenkins credentials
node['jenkins_cf']['jenkins_credentials'].each do |name, credential|
  jenkins_private_key_credentials name do
    id credential['id']
    description credential['description']
    private_key credential['private_key']
  end
end

# Install update center json before attempting to install plugins
directory "#{node['jenkins']['master']['home']}/updates/" do
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['user']
  action :create
end

execute 'update jenkins update center' do
  command "wget http://updates.jenkins-ci.org/update-center.json -qO- | sed '1d;$d'  > #{node['jenkins']['master']['home']}/updates/default.json"
  user node['jenkins']['master']['user']
  group node['jenkins']['master']['user']
  creates "#{node['jenkins']['master']['home']}/updates/default.json"
end

# Install plugins
%w{ git 
    scripttrigger 
    rbenv 
    parameterized-trigger 
    copyartifact 
    envinject 
    ansicolor 
    ws-cleanup }.each do |plugin|
  #jenkins_plugin plugin
  jenkins_command "install-plugin #{plugin}"
end
