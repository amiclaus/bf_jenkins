# HDL Jenkins files

This folder contains the script files that are used to setup and run build system automation for the HDL repository.

Scripts:

**1. Jenkinsfile** - pipeline script that can be directly imported into a Pipeline Job via "Pipeline script from SCM" definition. The job handles the entire process of build automation, from creating and handling individual jobs for each hdl project to building each item.

When configuring the  pipeline job, it needs to be configured manually by adding the following string parameters:
 - `BUILD_BRANCH` - HDL branch that will be used for the build process (i.e. `master`)
 - `XILINX_VERSION` - Xilnx version required for builds (i.e. `2018.2`)
 - `QUARTUS_VERSION` - Quartus version required for builds (i.e. `18.0`)
 - `BUILD_WORKSPACE` - custom path where the hdl repository content is stored (i.e `/emea/mediadata/jenkins/test-hdl-jenkins`)
 
 Besides the String parameters, when defining a "Pipeline script from SCM", the following SCM parameters must be added:
 - _SCM_: i.e. `Git` 
 - _Repository URL_: i.e. `git@gitlab.analog.com:Platformation/build-system-automation.git` 
 - _Branch Specifier_: i.e. `master`
 - _Script Path_ of the Jenkinsfile: i.e. `jobs/hdl/Jenkinsfile`
 
**2. generate_projects.groovy** - DSL script called within the 'Generate Project' stage of the pipeline script. It handles the job generation for each hdl project, including a pipeline job for parallel project builds and a weekly build job.
