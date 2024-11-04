# nix-devshell-problem

This repo demonstrates issues with copying Nix flakes between machines.

## Tasks

### clone

Clone this repo.

```bash
gh repo clone a-h/nix-devshell-problem
```

### export

Inside the repo, run the following commands to export the flake outputs, devshell, and the flake itself.

```bash
# Copy the packages (there's only 1).
nix copy --to file://$PWD/export .#packages.x86_64-linux.default
nix copy --derivation --to file://$PWD/export .#packages.x86_64-linux.default
# Copy the devshell.
nix copy --to file://$PWD/export .#devShells.x86_64-linux.default
nix copy --derivation --to file://$PWD/export .#devShells.x86_64-linux.default
# According to this post, the inputDerivation is needed to run the devshell.
# https://discourse.nixos.org/t/how-to-get-nix-store-path-of-nix-develop-shell/38846/2?u=a-h
nix copy --to file://$PWD/export .#devShells.x86_64-linux.default.inputDerivation
# Copy the flake inputs to the store.
nix flake archive --to file://$PWD/export
```

### create-docker-image

Create a Docker image to run the airgapped validation step.

```bash
docker buildx build --load --platform linux/amd64 -t nix-devshell-problem:latest .
```

### run-container

interactive: true

Run the container interactively to validate the export. Note that the `--network=none` flag is used to prevent the container from accessing the internet, the `--platform linux/amd64` flag is used to specify the platform, and the `--mount` flag is used to bind the current directory to the container.

```bash
docker run --entrypoint=/bin/bash --mount type=bind,source="$(pwd)",target=/code --workdir=/code --network=none -it --rm --platform linux/amd64 nix-devshell-problem:latest
```

### copy-export-into-local-store

Inside the container, import the export directory into the container's local store.

```bash
cd /code
nix copy --no-check-sigs --all --from file://$PWD/export/
```

### develop

Inside the container, run the devshell.

```bash
nix develop
```

Note that the devshell fails to run.

### build

Inside the container, run the build.

```bash
nix build
```

Note that the build fails to run.

## Reproduction

After running the export on the host machine, the export directory is copied into the container's local store. The devshell fails to run because the builder tries to download the source code from the internet.

This should not happen, because everything that the flake needs to build should already be in the export directory.

```
docker run --entrypoint=/bin/bash --mount type=bind,source=/Users/adrian/github.com/a-h/nix-devshell-problem,target=/code --workdir=/code --network=none -it --rm --platform linux/amd64 nix-devshell-problem:latest
```

The `/code` directory contains the Nix flake, and the export directory.

```bash
root@d369f4b7260a:/code# ls
Dockerfile  README.md  export  flake.lock  flake.nix  hello.sh  result
```

Importing the export directory into the container's local store works fine.

```bash
root@d369f4b7260a:/code# nix copy --no-check-sigs --all --from file://$PWD/export/
warning: you don't have Internet access; disabling some network-dependent features
```

But then, running `nix develop` or `nix build` fails.

```bash
root@d369f4b7260a:/code# nix develop
warning: you don't have Internet access; disabling some network-dependent features
warning: Git tree '/code' is dirty
error: builder for '/nix/store/5jrd75v747s76s16zxk59384xfcjqn58-bash-5.2.tar.gz.drv' failed with exit code 1;
       last 4 log lines:
       > error:
       >        … writing file '/nix/store/v28dv6l0qk3j382kp40bksa1v6h7dx9p-bash-5.2.tar.gz'
       >
       >        error: unable to download 'https://ftpmirror.gnu.org/bash/bash-5.2.tar.gz': Couldn't resolve host name (6)
       For full logs, run 'nix log /nix/store/5jrd75v747s76s16zxk59384xfcjqn58-bash-5.2.tar.gz.drv'.
error: 1 dependencies of derivation '/nix/store/hdpsnzp3vajlzbi6dmrbnkb6mhfc8axz-bash-5.2-p15.drv' failed to build
error: 1 dependencies of derivation '/nix/store/hpkl2vyxiwf7rwvjh9lpij7swp7igilx-bash-5.2-p15.drv' failed to build
error: 1 dependencies of derivation '/nix/store/kgag4vbp9csw1mqbig4r2dd1l2fri70s-bash-5.2-p15.drv' failed to build
error: 1 dependencies of derivation '/nix/store/lp1y9zymyyrn2hc5l8sycffd0048ls4z-bash-5.2-p15.drv' failed to build
error: 1 dependencies of derivation '/nix/store/dm7bl6lprdslgkcspsws8jk999b02a5q-bash-5.2.tar.gz.drv' failed to build
error (ignored): error: 1 dependencies of derivation '/nix/store/xjvqa1vlyfzay8z8nzkbzm5rl478l0fy-bash-interactive-5.2-p15.drv' failed to build
```

This is unexpected, since the export directory should contain everything that the flake needs to build.
