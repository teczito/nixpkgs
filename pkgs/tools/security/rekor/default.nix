{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:

let
  generic =
    {
      pname,
      packageToBuild,
      description,
    }:
    buildGoModule rec {
      inherit pname;
      version = "1.3.10";

      src = fetchFromGitHub {
        owner = "sigstore";
        repo = "rekor";
        rev = "v${version}";
        hash = "sha256-fxBLh7QrBBkUsVrONeFmrXtmRGNgkH7WnncMQ+E56Ok=";
        # populate values that require us to use git. By doing this in postFetch we
        # can delete .git afterwards and maintain better reproducibility of the src.
        leaveDotGit = true;
        postFetch = ''
          cd "$out"
          git rev-parse HEAD > $out/COMMIT
          # '0000-00-00T00:00:00Z'
          date -u -d "@$(git log -1 --pretty=%ct)" "+'%Y-%m-%dT%H:%M:%SZ'" > $out/SOURCE_DATE_EPOCH
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };

      vendorHash = "sha256-2ddpzKzVlmOgxsBtLB28fKZ2o4QvtrNZC+1wOny3Amk=";

      nativeBuildInputs = [ installShellFiles ];

      subPackages = [ packageToBuild ];

      ldflags = [
        "-s"
        "-w"
        "-X sigs.k8s.io/release-utils/version.gitVersion=v${version}"
        "-X sigs.k8s.io/release-utils/version.gitTreeState=clean"
      ];

      # ldflags based on metadata from git and source
      preBuild = ''
        ldflags+=" -X sigs.k8s.io/release-utils/version.gitCommit=$(cat COMMIT)"
        ldflags+=" -X sigs.k8s.io/release-utils/version.buildDate=$(cat SOURCE_DATE_EPOCH)"
      '';

      postInstall = ''
        installShellCompletion --cmd ${pname} \
          --bash <($out/bin/${pname} completion bash) \
          --fish <($out/bin/${pname} completion fish) \
          --zsh <($out/bin/${pname} completion zsh)
      '';

      meta = with lib; {
        inherit description;
        homepage = "https://github.com/sigstore/rekor";
        changelog = "https://github.com/sigstore/rekor/releases/tag/v${version}";
        license = licenses.asl20;
        maintainers = with maintainers; [
          lesuisse
          jk
          developer-guy
        ];
      };
    };
in
{
  rekor-cli = generic {
    pname = "rekor-cli";
    packageToBuild = "cmd/rekor-cli";
    description = "CLI client for Sigstore, the Signature Transparency Log";
  };
  rekor-server = generic {
    pname = "rekor-server";
    packageToBuild = "cmd/rekor-server";
    description = "Sigstore server, the Signature Transparency Log";
  };
}
