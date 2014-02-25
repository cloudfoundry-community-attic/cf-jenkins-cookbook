# dea_ng

node.set['vagrant']['url'] = 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.4.3_x86_64.deb'
node.set['vagrant']['checksum'] = 'dbd06de0f3560e2d046448d627bca0cbb0ee34b036ef605aa87ed20e6ad2684b'

include_recipe 'vagrant'

job_props = {
  repo: node['jenkins_cf']['git_repos']['dea_ng']['address'],
  branch: node['jenkins_cf']['git_repos']['dea_ng']['branch'],
  prepare: %Q[
    git submodule update --init
    bundle install

    # create your test VM
    export VAGRANT_DEFAULT_PROVIDER = 'lxc'
    bundle exec rake test_vm
  ],
  test: '',
  use_rbenv: true
}

jenkins_cf_job 'dea_ng' do
  config job_props
  template 'cf-component.xml'
end
