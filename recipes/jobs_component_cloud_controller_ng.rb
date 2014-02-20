# cloud_controller_ng

%w{ zip }.each { |package_name| package package_name }

job_props = {
  repo: node['jenkins_cf']['git_repos']['cloud_controller_ng']['address'],
  branch: node['jenkins_cf']['git_repos']['cloud_controller_ng']['branch'],
  prepare: %Q[
    git submodule update --init
    bundle install
  ],
  test: 'bundle exec parallel_rspec spec -s integration',
}

jenkins_cf_job 'cloud_controller_ng' do
  config job_props
  template 'cf-component.xml'
end
