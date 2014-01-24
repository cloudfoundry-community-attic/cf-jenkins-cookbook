name             'jenkins_cf'
maintainer       'BSkyB'
maintainer_email 'ryan.grenz@bskyb.com'
license          'All rights reserved'
description      'A build environment for Cloud Foundry v2 on Openstack'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.2'

%w(user git git_user apt ssh_known_hosts sudo vagrant).each { |cb| depends cb }
depends "jenkins", ">= 2.0.0"