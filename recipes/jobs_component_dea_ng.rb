# dea_ng

%w{ lxc }.each { |package_name| package package_name }

node.set['vagrant']['url'] = 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.5.4_x86_64.deb'
node.set['vagrant']['checksum'] = '08142c24d6d26a0c22edf74cc912d1fd4bbef533751fcaf74dbc1418f4d2da1f'
node.set['vagrant']['plugins'] = [
  "vagrant-lxc",
  {"name" => "vagrant-lxc", "version" => "0.7.0"}
]

include_recipe 'vagrant'

job_props = {
  repo: node['jenkins_cf']['git_repos']['dea_ng']['address'],
  branch: node['jenkins_cf']['git_repos']['dea_ng']['branch'],
  prepare: %Q[
        rm -rf $WORKSPACE/tmp/warden-test-infrastructure
    git submodule update --init
    bundle install

    # create your test VM
    export VAGRANT_DEFAULT_PROVIDER='lxc'
    vagrant box remove precise64
    vagrant box add precise64 http://bit.ly/vagrant-lxc-precise64-2013-10-23    
bundle exec rake test_vm
  ],
  test: '',
  use_rbenv: true  
}

jenkins_cf_job 'dea_ng' do
  config job_props
  template 'cf-component.xml'
end
