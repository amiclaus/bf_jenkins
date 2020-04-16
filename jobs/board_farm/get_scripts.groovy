import hudson.tools.*
import hudson.model.*
import jenkins.model.Jenkins
import hudson.util.RemotingDiagnostics;

def jenkins = Jenkins.instance
def computers = jenkins.slaves

index = 0

def tests_ws = '/home/pi/bf_prod_test'

computers.each{ 
  //assign label to slave
  it.setLabelString("board$index")
  folder('/board_farm/boards'){
  }
  job("/board_farm/boards/board$index"){
  	label("board$index")
	customWorkspace(tests_ws)
    scm {
      git {
        remote {
          branch('master')
          url('https://gitlab.analog.com/Platformation/board_farm_tests.git')
          credentials("BF_CREDENTIALS")
        }
      }
    }
    triggers {
      upstream(JOB_NAME, 'SUCCESS')
    }
  }
  index++
    
  Node slave = it.asNode()
  
  //Set slave usage
  slave.mode=Node.Mode.EXCLUSIVE
  
  //Add Git Tool location
  def gitToolDescriptor = Jenkins.getInstance().getDescriptor("hudson.plugins.git.GitTool")
  def toolLocation = new ToolLocationNodeProperty.ToolLocation(gitToolDescriptor, "git", "/usr/bin/git")
  def toolLocationProperty = new ToolLocationNodeProperty(toolLocation as List)
  slave.nodeProperties.add(toolLocationProperty)
}