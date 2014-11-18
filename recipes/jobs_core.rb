chef_gem 'chef-helpers'
require 'chef-helpers'

config = node['jenkins_cf']
jenkins_mode = config['mode']
deployments = config['deployments']
deployment_configs = deployments['config']  

# BOSH release build/deploy jobs #################################################################################

releases = config['releases']
release_configs = releases['config']

# Release Build jobs
if jenkins_mode.include?('build')

  releases['enabled'].each do |release_name|
    job_name = "#{release_name}-release-tgz"
    release_config = release_configs["#{release_name}"]

    job_config = config.dup
    job_config['release'] = {
      name: release_name,
      config: release_config
    }

    job_template = has_template?("#{job_name}.xml").nil? ? "generic-release-tgz.xml" : "#{job_name}.xml"

    jenkins_cf_job job_name do
      config job_config
      template job_template
    end
  end

end

# Release deployment-related jobs
if jenkins_mode.include?('deploy')

  deployments['enabled'].each do |deployment_name|
    %w{upload deploy}.each do |stage|
      deployment_config = deployment_configs[deployment_name]
      target_bosh = deployment_config['bosh']
      release_name = deployment_config['release'] || deployment_name
      release_config = release_configs[release_name]

      case stage
        when 'upload'
          next if deployment_name == 'bosh-outer'
          job_name = "#{release_name}-release-#{target_bosh}-#{stage}"
          job_desc = "Upload #{release_name} release to #{target_bosh} BOSH"
        when 'deploy' 
          job_name = "#{deployment_name}-#{stage}"
          job_desc = "Deploy #{release_name} release through #{target_bosh} BOSH"
      end

      log "Creating #{job_name} (#{job_desc})"

      cfg = {
        job_name: job_name,
        job_desc: job_desc,
        deployment: {
          name: deployment_name,
          config: deployment_config,
        },
        release: {
          name: release_name,
          config: release_config,
        },
        bosh: {
          name: target_bosh,
          config: deployment_configs["bosh-#{target_bosh}"]
        }
      }

      job_config = config.dup
      job_config['_'] = cfg

      job_template = has_template?("#{job_name}.xml").nil? ? "generic-release-#{stage}.xml" : "#{job_name}.xml"

      jenkins_cf_job job_name do
        config job_config
        template job_template
      end
    end
  end

end

# BOSH stemcell build/deploy jobs ################################################################################

# Stemcell tgz
# Install inner/outer bosh stemcell upload jobs
downstream_jobs = {
  outer: 'bosh-release-deploy',
  inner: 'cf-release-deploy',
}

stemcells = config['stemcells']
stemcells.each do |sc_name, sc_config|

  if jenkins_mode.include?('build')
    stemcell_tgz_job = "stemcell-tgz-#{sc_name}"

    stemcell_tgz_config = {
      stemcell_base_url: sc_config['stemcell_base_url'],
      stemcell: sc_config['stemcell']
    }

    jenkins_cf_job stemcell_tgz_job do
      config stemcell_tgz_config
      template sc_config['mode'] == 'dev' ? 'stemcell-builder.xml' : 'stemcell-watcher.xml'
    end
  end

  if jenkins_mode.include?('deploy')
    %w{ outer inner }.each do |bosh_layer|
      bosh_config = deployment_configs["bosh-#{bosh_layer}"]

      stemcell_upload_config = {
        director_ip: bosh_config['director_ip'],
        bosh_username: bosh_config['user'],
        bosh_password: bosh_config['password'],
        downstream_jobs: downstream_jobs[bosh_layer.to_sym],
        stemcell_artifact_source: stemcell_tgz_job
      }

      jenkins_cf_job "stemcell-#{bosh_layer}-upload-#{sc_name}" do
        config stemcell_upload_config
        template 'stemcell-uploader.xml'
      end
    end
  end

end
