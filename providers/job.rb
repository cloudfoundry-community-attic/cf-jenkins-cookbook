action :create do
  tmp_config = ::File.join(Chef::Config[:file_cache_path], "#{new_resource.name}-config.xml")

  template tmp_config do
    source new_resource.template ? new_resource.template : "#{new_resource.name}.xml"
    variables vars: new_resource.config
  end

  jenkins_job new_resource.name do
    config tmp_config
  end
end
