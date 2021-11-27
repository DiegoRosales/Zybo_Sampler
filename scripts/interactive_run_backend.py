import os,sys
import subprocess as sp
import signal

class interactive_run:

  VIVADO_PATH = ""
  base_cmd = "vivado -log ./results/vivado.log -jou ./results/vivado.jou -mode batch -source scripts/run.tcl -tclargs -cfg cfg/zybo_sampler.cfg.json"
  setup_cmd = "source {}/settings64.sh"

  ## Stages
  stage_pack          = 0
  stage_integ         = 0
  stage_gen_xilinx_ip = 0
  stage_impl          = 0
  stage_build_ws      = 0
  stage_lint          = 0

  def __init__(self, VIVADO_PATH):
    self.VIVADO_PATH = VIVADO_PATH
    result = self.print_vivado_version()
    if (result == 0):
      print(f"[INFO] - Initialized! Vivado Path = {VIVADO_PATH}")
    else:
      print("[ERROR] - There was an error while checking the Vivado version")

  def print_vivado_version(self):
    cmd = "vivado -version"
    return self.run_vivado(cmd)

  def reset_stages(self):
    self.stage_pack          = 0
    self.stage_integ         = 0
    self.stage_gen_xilinx_ip = 0
    self.stage_impl          = 0
    self.stage_build_ws      = 0
    self.stage_lint          = 0

  def generate_vivado_cmd(self):
    stages = []
    stages_str = ""
    if(self.stage_pack):
      stages.append("PACK")
    if(self.stage_integ):
      stages.append("INTEG")
    if(self.stage_gen_xilinx_ip):
      stages.append("GEN_XILINX_IP")
    if(self.stage_impl):
      stages.append("IMPL")
    if(self.stage_build_ws):
      stages.append("BUILD_WS")
    if(self.stage_lint):
      stages.append("LINT")

    for i in range(len(stages)):
      stages_str += stages[i]
      if (i < len(stages) - 1):
        stages_str += "+"

    new_cmd = f"{self.base_cmd} -stages \"{stages_str}\""
    print(new_cmd)
    return new_cmd


  def run_vivado(self, cmd):
    new_cmd = f"{self.setup_cmd.format(self.VIVADO_PATH)} ; {cmd}"
    print(f"Running command: {new_cmd}")
    return self.bash(new_cmd)

  def bash(self, cmd, print_stdout=True, print_stderr=True):
      proc = sp.Popen(cmd, stderr=sp.PIPE, stdout=sp.PIPE, shell=True, universal_newlines=True,
                      executable='/bin/bash')

      all_stdout = []
      all_stderr = []
      while proc.poll() is None:
          for stdout_line in proc.stdout:
              if stdout_line != '':
                  if print_stdout:
                      print(stdout_line, end='')
                  all_stdout.append(stdout_line)
          for stderr_line in proc.stderr:
              if stderr_line != '':
                  if print_stderr:
                      print(stderr_line, end='', file=sys.stderr)
                  all_stderr.append(stderr_line)

      stdout_text = ''.join(all_stdout)
      stderr_text = ''.join(all_stderr)
      return_code = proc.wait()
      if return_code != 0:
        print("[ERROR] - There was an error while running the command")
      else:
        print("[INFO] - Command completed with Exit Status 0")
      ## Return the error code
      return return_code
