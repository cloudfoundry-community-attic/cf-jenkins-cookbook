job_modes = node['jenkins_cf']['jobs']

# Install core BOSH tgz/upload jobs
%w{ cf-release cf-services-contrib-release bosh-release }.each do |bosh_release|
  %w{ tgz upload }.each do |cycle|
    job_name = "#{bosh_release}-#{cycle}"
    job_config = node['jenkins_cf'].dup
    job_config['mode'] = job_modes["#{job_name}"] || 'final'
    jenkins_cf_job "#{job_name}" do
      config job_config
      template "#{job_name}.xml"
    end  
  end
end

# Install core BOSH deploy jobs
%w{ cf-deploy cf-contrib-deploy bosh-inner-deploy bosh-outer-deploy }.each do |deployment_job|
  jenkins_cf_job "#{deployment_job}" do
    config node['jenkins_cf']
    template "#{deployment_job}.xml"
  end
end

# Stemcell tgz
jenkins_cf_job 'stemcell-tgz' do
  config node['jenkins_cf']
  template job_modes['stemcell-tgz'] == 'dev' ? 'stemcell-builder.xml' : 'stemcell-watcher.xml'
end

# Install inner/outer bosh stemcell upload jobs
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

# Install other core jobs
%w{ bosh-bats
    vcap-yeti }.each do |job_name|
  jenkins_cf_job job_name do
    config node['jenkins_cf']
  end
end
