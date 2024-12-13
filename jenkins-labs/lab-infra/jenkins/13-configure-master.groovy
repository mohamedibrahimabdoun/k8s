import jenkins.model.*
import org.jenkinsci.plugins.gitclient.verifier.*
import jenkins.*
import hudson.model.*
import hudson.security.*

def instance = Jenkins.getInstance().getDescriptor("org.jenkinsci.plugins.gitclient.GitHostKeyVerificationConfiguration")
strategy = new NoHostKeyVerificationStrategy()
instance.setSshHostKeyVerificationStrategy(strategy)
instance.save()