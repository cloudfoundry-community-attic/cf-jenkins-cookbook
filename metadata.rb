name             'jenkins_cf'
maintainer       'BSkyB'
maintainer_email 'ryan.grenz@bskyb.com'
license          'All rights reserved'
description      'A build environment for Cloud Foundry v2 on Openstack'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.2'

%w(jenkins user git_user apt ssh_known_hosts sudo).each { |cb| depends cb }
