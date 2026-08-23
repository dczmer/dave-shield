# Example of how to run the container from a project repo:
# ```
# # create a persistent /root volume
# docker volume inspect davehome >/dev/null 2>&1 \
#   || docker volume create davehome
# docker run --rm -e LOCAL_USER_ID=`id -u` \
#   -v "$(pwd)":/source \
#   -v davehome:/root \
#   -v /home/dave/.config/opencode:/root/.config/opencode \
#   -it opencode-container:latest
# ```
{
  pkgs,
  commonPkgs,
  ...
}:
pkgs.dockerTools.buildImage {
  name = "opencode-container";
  tag = "latest";

  copyToRoot =
    with pkgs;
    [
      pkgs.llm-agents.opencode

      # these make the docker environment a little more useful.
      dockerTools.usrBinEnv
      dockerTools.binSh
      dockerTools.caCertificates

      # NOTE: do not use fakeNss with shadowSetup
      dockerTools.fakeNss
    ]
    ++ commonPkgs;

  config = {
    Cmd = [ "${pkgs.llm-agents.opencode}/bin/opencode" ];
    #Volumes = { };
    WorkingDir = "/source";
    Env = [ "OPENCODE_CONFIG_DIR=/root/.config/opencode" ];
  };

  # NOTE: do not use fakeNss with shadowSetup
  #runAsRoot = ''
  #  #!${pkgs.runtimeShell}
  #  ${pkgs.dockerTools.shadowSetup}
  #  groupadd -r -g 100 users
  #  useradd -r -m -g users -u 1001 dave
  #'';
}
