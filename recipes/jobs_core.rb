# Install BOSH upload/deploy jobs
%w{ bosh-outer-deploy 
    bosh-inner-deploy 
    bosh-release-upload 
    cf-release-final-upload 
    cf-release-final-deploy
    cf-services-contrib-release-final-upload 
    stemcell-watcher 
    vcap-yeti 
    bosh-bats }.each do |job_name|
  jenkins_cf_job job_name do
    config node['jenkins_cf']
  end
end

downstream_jobs = {
  :outer => "bosh-release-deploy",
  :inner => "cf-release-final-deploy" 
}

# Install stemcell upload jobs
%w{ outer inner }.each do |bosh_layer|
  bosh_config = node['jenkins_cf']["#{bosh_layer}_bosh"]

  stemcell_job_config = {
    :director_ip => bosh_config['director_ip'],
    :bosh_username => bosh_config['user'],
    :bosh_password => bosh_config['pass'],
    :downstream_jobs => downstream_jobs[bosh_layer.to_sym]
  }

  jenkins_cf_job "stemcell-#{bosh_layer}-upload" do
    config stemcell_job_config
    template "stemcell-uploader.xml"
  end
end