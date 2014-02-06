# Cookbook Name: jenkins-cf
# Recipe: default

include_recipe 'jenkins_cf::server'
include_recipe 'jenkins_cf::jobs_core'

jenkins_command 'safe-restart'
