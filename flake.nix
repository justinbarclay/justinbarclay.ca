{
  description = "A simple Go package";

  # Nixpkgs / NixOS version to use.
  inputs = {
    nixpkgs = {
      url = "nixpkgs/nixos-unstable";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Normally this is something that is set as a git submodule
        # for hugo projects. But nix doesn't have access to the git
        # state of our project. So we make a custom derivation, skip the build phase and wholesale copy source directory
        hugo-coder = pkgs.stdenv.mkDerivation
          {
            name = "hugo-coder";
            # It's important to use the same revision as is specified
            # in your submodule
            rev = "5c2476be1c29563b6dd06c15fb9206d2ca50efae";
            src = pkgs.fetchFromGitHub {
              owner = "luizdepra";
              repo = "hugo-coder";
              rev = "5c2476be1c29563b6dd06c15fb9206d2ca50efae";
              # To get this sha use AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
              # and nix will tell you
              sha256 = "v0t7DVCml7pv7gU0IDy/xr61d/ohfC1xwzXYsVUoC+g=";
            };

            # We want to skip the buildPhase because there is nothing to build.
            # for more info https://nixos.org/manual/nixpkgs/unstable/#sec-stdenv-phases
            phases = [ "unpackPhase" "installPhase" ];

            # We use hugo-coder because for whatever hugo was
            # complaining about this and I didn't care to figure it
            # out or fix it.
            installPhase = ''
              mkdir -p $out/hugo-coder
              cp -r $src/* $out/hugo-coder
            '';

          };

        blog = pkgs.stdenv.mkDerivation {
          name = "justinbarclay.ca";
          version = "1.0.0";
          src = ./.;
          buildInputs = with pkgs; [
            hugo
          ];

          # Using git submodule init here is an antipractice but I am being quick and dirty
          # and doing it right is a _lot_ more work
          buildPhase = ''
            export HUGO_ENV=production
            work=$(mktemp -d)
            cp -r $src/* $work
            (cd $work && hugo --themesDir=${hugo-coder} --minify)
          '';

          # This is the output of the derivation.  You should see this
          # in the ./result folder when building locally
          installPhase = ''

            cp -r $work/public $out
          '';
        };
      in
      {
        # Add dependencies that are only needed for development
        packages.blog = blog;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ hugo ];
        };
      }
    );
}
