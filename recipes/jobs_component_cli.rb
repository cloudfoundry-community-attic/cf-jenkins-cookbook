# cli (go)

job_props = {
  repo: node['jenkins_cf']['git_repos']['cli']['address'],
  branch: node['jenkins_cf']['git_repos']['cli']['branch'],
  prepare: %Q[
    export GOPATH=~/go
    export PATH=~/go/bin:$PATH    
    git submodule update --init --recursive
  ],
  test: %Q[
    ./bin/go test -bench . -benchmem cf/...
    ./bin/build
  ],
  artifact: 'out/cf'
}

jenkins_cf_job 'component.cli' do
  config job_props
  template 'cf-component.xml'
end
