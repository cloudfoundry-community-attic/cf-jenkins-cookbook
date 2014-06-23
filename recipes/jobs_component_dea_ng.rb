# dea_ng

# vagrant setup
node.set['vagrant']['url'] = 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.5.4_x86_64.deb'
node.set['vagrant']['checksum'] = '08142c24d6d26a0c22edf74cc912d1fd4bbef533751fcaf74dbc1418f4d2da1f'
node.set['vagrant']['plugins'] = [
  "vagrant-vsphere",
  {"name" => "vagrant-vsphere", "version" => "0.8.2"}
]
include_recipe 'vagrant'

# iaas specific vagrant config
config_props = node['jenkins_cf']['jobs']['component.dea_ng']

case node['jenkins_cf']['iaas']
  when 'vsphere'
    vagrant_setup = %Q[
        vagrant plugin install vagrant-vsphere

        echo '{ "provider": "vSphere" }' > metadata.json
        tar cvzf dummy.box ./metadata.json
        vagrant box remove dummy --provider=vSphere || true
        vagrant box add dummy dummy.box || true

        export DEA_TEST_VM_IP="#{config_props['test_vm_ip']}"
        export DEA_VS_DC="#{config_props['vsphere_props']['data_center_name']}"
        export DEA_VS_HOST="#{config_props['vsphere_props']['host']}"
        export DEA_VS_COMPUTE="#{config_props['vsphere_props']['compute_resource_name']}"
        export DEA_VS_RES_POOL="#{config_props['vsphere_props']['resource_pool_name']}"
        export DEA_VS_CUST_SPEC="#{config_props['vsphere_props']['customization_spec_name']}"
        export DEA_VS_TEMPLATE="#{config_props['vsphere_props']['template_name']}"
        export DEA_VS_USER="#{config_props['vsphere_props']['user']}"
        export DEA_VS_PASS="#{config_props['vsphere_props']['password']}"

        export VAGRANT_DEFAULT_PROVIDER='vsphere'
    ]
end

job_props = {
  repo: node['jenkins_cf']['git_repos']['dea_ng']['address'],
  branch: node['jenkins_cf']['git_repos']['dea_ng']['branch'],
  prepare: %Q[
    git submodule update --init
    bundle install

    #{vagrant_setup}
  ],
  test: '$WORKSPACE/bin/test_in_vm',
  use_rbenv: true
}

jenkins_cf_job 'component.dea_ng' do
  config job_props
  template 'cf-component.xml'
end
