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
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      expertpkg,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        expert = expertpkg.packages.${system}.expert;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
            pkgs.erlang_28
            pkgs.beam.packages.erlang_28.elixir_1_19
            pkgs.elixir-ls
            pkgs.libnotify
            pkgs.inotify-tools
            expert
          ];
          shellHook = ''
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
        };

      }
    );
}
