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
