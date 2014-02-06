# Install core BOSH upload/deploy jobs

%w{ bosh-outer-deploy 
    bosh-inner-deploy 
    bosh-release-upload 
    cf-release-upload 
    cf-release-deploy
    cf-services-contrib-release-upload 
    vcap-yeti }.each do |job_name|
  jenkins_cf_job job_name do
    config node['jenkins_cf']
  end
end

# Install stemcell upload jobs
downstream_jobs = {
  outer: 'bosh-release-deploy',
  inner: 'cf-release-deploy',
}

%w{ outer inner }.each do |bosh_layer|
  bosh_config = node['jenkins_cf']["#{bosh_layer}_bosh"]

  stemcell_job_config = {
    director_ip: bosh_config['director_ip'],
    bosh_username: bosh_config['user'],
    bosh_password: bosh_config['pass'],
    downstream_jobs: downstream_jobs[bosh_layer.to_sym],
  }

  jenkins_cf_job "stemcell-#{bosh_layer}-upload" do
    config stemcell_job_config
    template 'stemcell-uploader.xml'
  end
end
