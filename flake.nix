{
  # The document, and the suite that proves it. `bin/generate-specs` turns
  # every operation described here into an RSpec example; `bundle exec rspec`
  # aims them at Monzo.
  description = "Monzo Developer API OpenAPI description, and its conformance suite";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }:
    (utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        gems = pkgs.bundlerEnv {
          name = "openapi-schema-monzo-gems";
          ruby = pkgs.ruby;
          gemdir = ./.;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            gems
            gems.wrappedRuby

            # bin/generate-specs: one RSpec file per tag, from the templates
            # in templates/rspec. No custom generator -- the stock Ruby one
            # already groups operations the way the specs want them, so only
            # its test template is replaced.
            pkgs.openapi-generator-cli

            # `bundix -l` after a Gemfile change.
            pkgs.bundix

            # The lint.
            pkgs.vacuum-go
          ];
        };
      }));
}
