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
# Install inner/outer bosh stemcell upload jobs
downstream_jobs = {
  outer: 'bosh-release-deploy',
  inner: 'cf-release-deploy',
}

stemcells = node['jenkins_cf']['stemcells']
stemcells.each do |sc_name, sc_config|
  stemcell_tgz_job = "stemcell-tgz-#{sc_name}"

  stemcell_tgz_config = {
    stemcell_base_url: sc_config['stemcell_base_url'],
    stemcell: sc_config['stemcell']
  }

  jenkins_cf_job stemcell_tgz_job do
    config stemcell_tgz_config
    template sc_config['mode'] == 'dev' ? 'stemcell-builder.xml' : 'stemcell-watcher.xml'
  end

  %w{ outer inner }.each do |bosh_layer|
    bosh_config = node['jenkins_cf']["#{bosh_layer}_bosh"]

    stemcell_upload_config = {
      director_ip: bosh_config['director_ip'],
      bosh_username: bosh_config['user'],
      bosh_password: bosh_config['pass'],
      downstream_jobs: downstream_jobs[bosh_layer.to_sym],
      stemcell_artifact_source: stemcell_tgz_job
    }

    jenkins_cf_job "stemcell-#{bosh_layer}-upload-#{sc_name}" do
      config stemcell_upload_config
      template 'stemcell-uploader.xml'
    end
  end
end
