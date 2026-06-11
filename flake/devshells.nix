{lib, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };

    devShells =
      {
        default = pkgs.mkShell {
          packages = with pkgs; [
            alejandra
            statix
            deadnix
            nixd
            treefmt
          ];
          shellHook = ''
            if [ -t 1 ]; then
              fastfetch
            fi
          '';
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        htb = pkgs.mkShell {
          packages = with pkgs; [
            nmap
            rustscan
            masscan
            enum4linux-ng
            dnsenum
            burpsuite
            feroxbuster
            gobuster
            ffuf
            sqlmap
            nuclei
            wfuzz
            metasploit
            exploitdb
            python3Packages.pwntools
            evil-winrm
            netexec
            python3Packages.impacket
            bloodhound
            responder
            smbmap
            hashcat
            john
            thc-hydra
            chisel
            ligolo-ng
            proxychains-ng
            ghidra
            wireshark
            tcpdump
            netcat-gnu
            pwncat
            seclists
            wordlists
            openvpn
            rlwrap
          ];
          shellHook = ''
            echo ""
            echo "  HTB / Pentesting Shell"
            echo "  nmap rustscan masscan       Scanning"
            echo "  feroxbuster gobuster ffuf   Web"
            echo "  evil-winrm netexec impacket Win/AD"
            echo "  metasploit sqlmap pwntools  Exploit"
            echo "  hashcat john hydra          Passwords"
            echo "  chisel ligolo proxychains   Pivoting"
            echo "  ghidra                      Rev. Eng."
            echo "  wireshark tcpdump netcat    Network"
            echo "  seclists wordlists          Wordlists"
            echo ""
          '';
        };
      };
  };
}
