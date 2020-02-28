import static groovy.io.FileType.FILES

def projectList = []

/* Get full path used for creating the jobs */
def projJobPath = JOB_NAME.substring(0, JOB_NAME.lastIndexOf("/"))

/* Function implementing the Pipeline Script for building all projects */
def genBuildProjectsScript(prefix, list)
{
	def buildAllScript = "parallel("
	list.eachWithIndex { item, index ->
		item = item.replace("/", ".")
		buildAllScript += "\n b$index: {build job: '$prefix/$item'},"
	}
	buildAllScript += "\n)\nfailFast: false"
	buildAllScript
}

/* Get all projects from the HDL repository */
new File(HDL_WORKSPACE).eachFileRecurse(FILES)
{
	if(it.name.endsWith('system_project.tcl')) {
		def idx = it.path.lastIndexOf("/projects/") + "/projects/".length()
		def jobPath = it.path.substring(idx, it.path.lastIndexOf("/"))
		projectList.add(jobPath)
	}
}

def buildAllProjects = genBuildProjectsScript(projJobPath + "/projects", projectList)

/* Create job that builds all projecst */
pipelineJob(projJobPath + "/build-projects")
{
	definition {
		parameters {
			stringParam("PATH", PATH)
		}
		triggers {
			upstream(JOB_NAME, 'SUCCESS')
		}
		cps {
			script(buildAllProjects)
			sandbox()
		}
	}
}

/* Create job for weekly builds */
job(projJobPath + "/weekly-build")
{
	triggers {
		cron("H  12  *  *  7")
	}
	steps {
		shell("rm -rf ${HDL_WORKSPACE}")
	}
	publishers {
		downstream(JOB_NAME, 'SUCCESS')
	}
}

/* Create folder that will contain jobs for each project */
folder(projJobPath + "/projects")
{
	description('Folder holding jobs for all HDL projects')
}

/* Create job for each project and add them to the projects folder */
projectList.each {
	def jobName = it.replace("/", ".")
	def projWorkspace = it
	job(projJobPath + "/projects/" + jobName)
	{
		customWorkspace(HDL_WORKSPACE + '/projects/' + projWorkspace)
		parameters {
			stringParam("PATH", PATH)
		}
		steps {
			shell("make VERBOSE=1")
		}
	}
}
