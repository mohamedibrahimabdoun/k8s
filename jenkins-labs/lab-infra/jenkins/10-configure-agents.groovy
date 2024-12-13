import jenkins.model.*
import hudson.model.*
import hudson.slaves.*
import hudson.plugins.sshslaves.*
import hudson.slaves.EnvironmentVariablesNodeProperty.Entry
import hudson.plugins.sshslaves.verifiers.*

import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

// SET THE INITIAL SSH CREDENTIALS
global_domain = Domain.global()

credentials_store = Jenkins.instance.getExtensionList(
  'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
)[0].getStore()

credentials = new BasicSSHUserPrivateKey(
  CredentialsScope.SYSTEM,
  "ssh-agent-key",
  "jenkins",
  new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(
    '/ssh-keys/vagrant_insecure_key'
  ),
  '',
  "SSH Key for the Agent"
)

credentials_store.addCredentials(global_domain, credentials)
SshHostKeyVerificationStrategy doNotVerifyHostKey = new NonVerifyingKeyVerificationStrategy()

// Get environment variable for autoconfiguration
def env = System.getenv()
String baseJvmOpts = env['BASE_JVM_OPTS']

// CREATE THE JDK17 AGENT
SSHLauncher jdk17Launcher = new SSHLauncher("jdk17-ssh-agent", 22, "ssh-agent-key", baseJvmOpts, "", "", "", 33, 3, 5, doNotVerifyHostKey)
Slave jdk17SSHAgent = new DumbSlave("jdk17-node", "/home/jenkins", jdk17Launcher)
jdk17SSHAgent.setLabelString("docker maven jdk17 jdk-17 java17 java-17 go-1.21.8 java docker dind docker-in-docker")
jdk17SSHAgent.setNodeDescription("Agent node for JDK17")
jdk17SSHAgent.setNumExecutors(2)
List<Entry> jdk17SSHAgentEnv = new ArrayList<Entry>();
jdk17SSHAgentEnv.add(new Entry("JAVA_HOME","/usr/lib/jvm/java-17-openjdk"))
EnvironmentVariablesNodeProperty jdk17SSHAgentEnvPro = new EnvironmentVariablesNodeProperty(jdk17SSHAgentEnv);
jdk17SSHAgent.getNodeProperties().add(jdk17SSHAgentEnvPro)
Jenkins.instance.addNode(jdk17SSHAgent)

// Add JDK 21 Agent
SSHLauncher jdk21Launcher = new SSHLauncher("jdk21-ssh-agent", 22, "ssh-agent-key", baseJvmOpts, "", "", "", 33, 3, 5, doNotVerifyHostKey)
Slave jdk21SSHAgent = new DumbSlave("jdk21-node", "/home/jenkins", jdk21Launcher)
jdk21SSHAgent.setLabelString("maven jdk21 jdk-21 java21 java-21 go-1.22.2")
jdk21SSHAgent.setNodeDescription("Agent node for JDK21")
jdk21SSHAgent.setNumExecutors(2)
List<Entry> jdk21SSHAgentEnv = new ArrayList<Entry>();
jdk21SSHAgentEnv.add(new Entry("JAVA_HOME","/usr/lib/jvm/java-21-openjdk"))
EnvironmentVariablesNodeProperty jdk21SSHAgentEnvPro = new EnvironmentVariablesNodeProperty(jdk21SSHAgentEnv);
jdk21SSHAgent.getNodeProperties().add(jdk21SSHAgentEnvPro)
Jenkins.instance.addNode(jdk21SSHAgent)