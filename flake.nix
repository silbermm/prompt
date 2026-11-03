{
  description = "Prompt";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    expertpkg.url = "github:elixir-lang/expert";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    agent-jail = {
      url = "github:GetThru/agent-jail";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      expertpkg,
      agent-jail,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        expert = expertpkg.packages.${system}.expert;
        erlang = pkgs.beam28Packages.erlang;
        elixir = pkgs.beam28Packages.elixir_1_19;
        # Claude Code and opencode in a bubblewrap jail. The jail mounts the
        # current directory, so the agents need the toolchain on their PATH and
        # the project-local mix and hex variables from the shellHook below.
        agents = agent-jail.lib.mkAgents {
          inherit pkgs;
          extraPkgs = [
            erlang
            elixir
          ];
          extraJailOptions = c: [
            (c.try-fwd-env "MIX_HOME")
            (c.try-fwd-env "HEX_HOME")
            (c.try-fwd-env "ERL_LIBS")
            (c.try-fwd-env "ERL_AFLAGS")
          ];
        };
        erlangNext = pkgs.beam29Packages.erlang;
        elixirNext = pkgs.beam29Packages.elixir_1_20;
        # Keep mix, hex, and the erlang shell history local to this checkout.
        # Shared by the default, ci, and ci-next shells.
        mixShellHook = ''
          # limit mix to current project
          mkdir -p .nix-mix
          export MIX_HOME=$PWD/.nix-mix
          export PATH=$MIX_HOME/bin:$PATH
          export PATH=$MIX_HOME/escripts:$PATH

          # limit hex to current project
          mkdir -p .nix-hex
          export HEX_HOME=$PWD/.nix-hex
          export ERL_LIBS=$HEX_HOME/lib/erlang/lib
          export PATH=$HEX_HOME/bin:$PATH

          # limit history to current project
          export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_path '\"$PWD/.erlang-history\"'"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
            erlang
            elixir
            pkgs.elixir-ls
            pkgs.libnotify
            pkgs.inotify-tools
            expert
            agents.claude-code
            agents.opencode
          ];
          shellHook = mixShellHook;
        };

        # Minimal shell for CI: only the BEAM toolchain, no editor or agent
        # tooling, so CI never has to build expert or the jailed agents.
        devShells.ci = pkgs.mkShell {
          packages = [
            erlang
            elixir
          ];
          shellHook = mixShellHook;
        };

        # Same as ci, on the next Erlang and Elixir, to catch 1.20 breakage early.
        devShells.ci-next = pkgs.mkShell {
          packages = [
            erlangNext
            elixirNext
          ];
          shellHook = mixShellHook;
        };
      }
    );
}
