import jenkins.*;
import jenkins.model.*;
import hudson.*;
import hudson.model.*;

goName = "go"
goVersion = "1.17.2"
println("Checking GO installations...")

// Grab the GO "task" (which is the plugin handle).
goPlugin = Jenkins.instance.getExtensionList(org.jenkinsci.plugins.golang.GolangBuildWrapper.DescriptorImpl.class)[0]

// Check for a matching installation.
goInstall = goPlugin.installations.find {
   install -> install.name.equals(goName)
}

// If no match was found, add an installation.
if(goInstall == null) {
   println("No GO install found. Adding...")

   newGOInstall = new org.jenkinsci.plugins.golang.GolangInstallation('go', null,
    [new hudson.tools.InstallSourceProperty([new org.jenkinsci.plugins.golang.GolangInstaller(goVersion)])]
)

   goPlugin.installations += newGOInstall
   goPlugin.save()

   println("GO install added.")
} else {
        println("GO install found. Done.")
}