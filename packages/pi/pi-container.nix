# Example of how to run the container from a project repo:
# ```
# # create a persistent /root volume
# docker volume inspect davehome >/dev/null 2>&1 \
#   || docker volume create davehome
# docker run --rm -e LOCAL_USER_ID=`id -u` \
#   -v "$(pwd)":/source \
#   -v davehome:/root \
#   -v /home/dave/source/dave-shield/packages/pi/config:/root/.pi/agent \
#   -it pi-coding-agent-container:latest
# ```
{
  pkgs,
  commonPkgs,
  ...
}:
pkgs.dockerTools.buildImage {
  name = "pi-coding-agent-container";
  tag = "latest";

  copyToRoot =
    with pkgs;
    [
      pkgs.llm-agents.pi

      # these make the docker environment a little more useful.
      dockerTools.usrBinEnv
      dockerTools.binSh
      dockerTools.caCertificates

      # NOTE: do not use fakeNss with shadowSetup
      dockerTools.fakeNss
    ]
    ++ commonPkgs;

  config = {
    Cmd = [ "${pkgs.llm-agents.pi}/bin/pi" ];
    #Volumes = { };
    WorkingDir = "/source";
    Env = [
      "PI_CODING_AGENT_DIR=/root/.pi/agent"
      "XDG_CONFIG_HOME=/root/.config"
      "XDG_CACHE_HOME=/root/.cache"
      "XDG_DATA_HOME=/root/.local/share"
      "XDG_STATE_HOME=/root/.local/state"
    ];
  };

  # NOTE: do not use fakeNss with shadowSetup
  #runAsRoot = ''
  #  #!${pkgs.runtimeShell}
  #  ${pkgs.dockerTools.shadowSetup}
  #  groupadd -r -g 100 users
  #  useradd -r -m -g users -u 1001 dave
  #'';
}
