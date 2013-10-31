# This Micro (or full) BOSH should already be deployed in your IaaS before you start

# Inner/Outer BOSH configurations
default['jenkins_cf']['outer_bosh']['director_ip']  = ''					 
default['jenkins_cf']['outer_bosh']['user'] = 'admin'
default['jenkins_cf']['outer_bosh']['pass'] = 'admin'

default['jenkins_cf']['inner_bosh']['director_ip'] = 'localhost' # Inner BOSH director floating ip
default['jenkins_cf']['inner_bosh']['powerdns_ip'] = 'localhost' # Inner BOSH powerdns floating ip
default['jenkins_cf']['inner_bosh']['user'] = 'admin' # Inner BOSH username
default['jenkins_cf']['inner_bosh']['pass'] = 'admin' # Inner BOSH password
default['jenkins_cf']['inner_bosh']['net_id'] = '' # Inner BOSH's quantum/neutron network id to use for cloud ip assignments

default['jenkins_cf']['cloud_controller']['ip'] = '' # Floating IP the cloud controller should use
default['jenkins_cf']['cloud_controller']['root_domain']= '' # Root CFv2 domain used in this deployment
default['jenkins_cf']['cloud_controller']['admin_user']	= 'admin'
default['jenkins_cf']['cloud_controller']['admin_pass']	= 'c1oudc0wc1oudc0w'

# Openstack settings
default['jenkins_cf']['openstack']['auth_url'] = 'http://xxx.xxx.xxx.xxx:5000/v2.0/tokens' # openstack API Identity url
default['jenkins_cf']['openstack']['user'] = 'admin' # openstack API user
default['jenkins_cf']['openstack']['api_key'] = 'admin' # openstack API password
default['jenkins_cf']['openstack']['tenant'] = 'cf' # openstack API tenant

# Jenkins settings
default['jenkins_cf']['git']['user'] = 'Jenkins'
default['jenkins_cf']['git']['email'] = 'jenkins@cf.org'
default['jenkins_cf']['git']['known_hosts'] = [ ] # Add a git server to known host to ensure using ssh keys wont prompt

# BOSH
default['jenkins_cf']['bosh_manifest_git_repo'] = 'git@github.com:user/bosh-manifests.git'

# Stemcell 
default['jenkins_cf']['stemcell_base_url'] = 'http://bosh-jenkins-artifacts.s3.amazonaws.com'
default['jenkins_cf']['stemcell'] = 'bosh-stemcell/openstack/bosh-stemcell-latest-openstack-kvm-ubuntu.tgz'	# Stemcell to use across the stack