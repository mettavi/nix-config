# PUSHING TO MY PERSONAL CACHIX CACHE

## SELECTIVELY PUSHING HEAVY PACKAGES FLAGGED BY THE GITHUB CI GUARD SCRIPT

Use the `cachix-sops` wrapper (see `/home/shared/programs.nix`)
to wrap the `CACHIX_AUTH_TOKEN` secret from sops into the `cachix` binary.

1. Make sure you’re on the same lock file as CI

   The `nix.yml` guard script fires on the weekly update-flake-lock PR, whose flake.lock is newer than your local one.
   Before building anything, check out the PR’s branch. If you build on an older lock,
   you’ll upload outputs with different hashes than the ones CI needs, and the guard will fire again.

   - `gh pr checkout <number> --force`, or
   - `git fetch origin && git switch --detach origin/<update-branch>`

   > [!NOTE] What the checkout does and doesn’t do
   > A checkout only swaps the files in your working directory. It doesn’t create any .drv files.

1. Evaluate the system, which makes Nix write the .drv files into your store.

   ```sh
   nix build --dry-run .#nixosConfigurations.oona.config.system.build.toplevel # writes the .drv files
   ls /nix/store/<hash>-vtk-9.5.2.drv # confirm it exists
   ```

   > [!NOTE]
   > If the `ls` fails after the evaluation, your local evaluation differs from CI's,
   > usually because of the wrong branch or uncommitted changes to flake inputs.
   > In that case, jump to step 4.

1. Run `nix-store --realise` on the path the guard printed.

   > [!NOTE]
   > `nix-store --realise` needs the .drv file (step 2) to already be in your local store.

   ```sh
   # will build locally first if necessary
   nix-store --realise /nix/store/<hash>-vtk-9.5.2.drv | cachix-sops push mettavi`
   # for several derivations at once:
   printf '%s\n' /nix/store/<hash>-vtk-9.5.2.drv /nix/store/<hash>-opencv-4.13.0.drv \
     | xargs -n1 nix-store --realise | cachix-sops push mettavi
   ```

1. If you don’t have the `.drv`, use `nix build`

   > [!NOTE]
   > `nix build` doesn’t need the .drv path from the log, but it does depend on matching CI’s lock file,
   > so the checkout (step 1) still applies. The heavy derivations only need matching lock files,
   > not an identical working tree, so an unrelated dirty file elsewhere in your repo doesn’t matter.

   ```sh
   nix build --no-link --print-out-paths \
   '.#nixosConfigurations.oona.pkgs.vtk^*' | cachix-sops push mettavi
   # NB: The kernel uses its own attribute (.#nixosConfigurations.oona.config.boot.kernelPackages.kernel^*).
   ```

1. Check afterwards

   ```sh
   # Take the hash from one pushed output path (the 32 characters after /nix/store/) and confirm it’s in your cache.
   # A 200 means CI will fetch it instead of building.
   curl -s -o /dev/null -w '%{http_code}\n' https://mettavi.cachix.org/<hash>.narinfo
   # Afterwards, run `git switch -` to go back to your usual branch.
   ```

## BULK PUSHING ALL PACKAGES

1. Download the raw log from the GitHub CI run.

1. Push all missing packages:

   ```sh
   sed -n '/derivations will be built/,/paths will be fetched/p' job-logs.txt \
   | grep -oE '/nix/store/[a-z0-9]{32}-[^ ]+\.drv' \
   | while read -r d; do nix-store -q --outputs "$d" 2>/dev/null; done \
   | while read -r o; do [ -e "$o" ] && echo "$o"; done \
   | grep -v -- '-linux-cachyos-latest-7.3.1-dev$' \ # exclude packages here
   | cachix-sops push mettavi
   ```
