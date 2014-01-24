action :create do
	tmp_config = "/tmp/#{new_resource.name}-config.xml"

	jenkins_job new_resource.name do
	  config tmp_config
	end

	template tmp_config do
	  source (new_resource.template) ? new_resource.template : "#{new_resource.name}.xml"
	  variables :vars => new_resource.config
	end		
end