# cli (go)

job_props = {
  repo: node['jenkins_cf']['git_repos']['cli']['address'],
  branch: node['jenkins_cf']['git_repos']['cli']['branch'],
  prepare: %Q[
    git submodule update --init --recursive
  ],
  test: './bin/go test -bench . -benchmem cf/...',
}

jenkins_cf_job 'cli' do
  config job_props
  template 'cf-component.xml'
end

