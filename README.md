# nix-devshell-problem

This repo demonstrates issues with copying Nix flakes between machines.

See the original commit for the issue, and this commit for a successful workaround for the issue.

## Tasks

### clone

Clone this repo.

```bash
gh repo clone a-h/nix-devshell-problem
```

### export

Inside the repo, run the following commands to export the flake outputs, devshell, and the flake itself.

```bash
export NIXPKGS_COMMIT=`jq -r '.nodes.[.nodes.[.root].inputs.nixpkgs].locked | "\(.type):\(.owner)/\(.repo)/\(.rev)"' flake.lock`
nix copy --to file://$PWD/export "$NIXPKGS_COMMIT#legacyPackages.x86_64-linux.stdenv"
nix copy --to file://$PWD/export "$NIXPKGS_COMMIT#legacyPackages.x86_64-linux.bashInteractive"
# Copy the packages (there's only 1).
nix copy --to file://$PWD/export .#packages.x86_64-linux.default
nix copy --derivation --to file://$PWD/export .#packages.x86_64-linux.default
# Copy the devshell contents.
nix copy --to file://$PWD/export .#devShells.x86_64-linux.default
nix copy --derivation --to file://$PWD/export .#devShells.x86_64-linux.default
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

### build

Inside the container, run the build.

```bash
nix build
```
