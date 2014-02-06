# cf-jenkins in dev mode

node.set['jenkins_cf']['build_type'] = 'dev'

include_recipe 'jenkins_cf::server'
include_recipe 'jenkins_cf::jobs_core'

# Additional dev-specific jobs 
%w{ stemcell-builder  
    bosh-bats }.each do |job_name|
  jenkins_cf_job job_name do
    config node['jenkins_cf']
  end
end

include_recipe 'jenkins_cf::jobs_component'

#jenkins_command 'safe-restart'