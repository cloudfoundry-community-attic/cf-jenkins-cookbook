# cli (go)

job_props = {
  repo: 'https://github.com/cloudfoundry/cli.git',
  branch: 'master',
  prepare: %Q[
    git submodule update --init --recursive
  ],
  test: './bin/go test -bench . -benchmem cf/...',
}

jenkins_cf_job 'cli' do
  config job_props
  template 'cf-component.xml'
end

