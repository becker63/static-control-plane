{
  config,
  lib,
  pkgs,
  ...
}:

let
  frpsKclSrc = ./frps.k;

  frpsConfigDrv =
    pkgs.runCommand "frps-config"
      {
        nativeBuildInputs = [ pkgs.kcl ];
      }
      ''
        mkdir -p $out

        # Render KCL to JSON
        kcl ${frpsKclSrc} --format json > $out/frps.json
      '';
in
{
  networking.hostName = "frps-node";
  time.timeZone = "UTC";

  environment.systemPackages = [
    pkgs.kcl
    pkgs.frp
  ];

  systemd.services.frps = {
    description = "FRPS client";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.frp}/bin/frps \
          -c ${frpsConfigDrv}/frps.json
      '';

      Restart = "always";
      RestartSec = 2;
    };
  };

  systemd.network.wait-online.enable = true;
}
