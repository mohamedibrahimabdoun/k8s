import jenkins.model.*

def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()

jenkinsLocationConfiguration.setAdminAddress("Student <student@lfs267training.com>")   

jenkinsLocationConfiguration.save()