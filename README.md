# caddy-dns-OCI
I created this project to avoid having to manually update my custom caddy images.
It checks for updates every hour and rebuilds the images accordingly.

## Which plugins are supported?
Pretty much all plugins except lego-deprecated and plugins affected by https://github.com/FarisZR/caddy-dns-OCI/issues/1 or https://github.com/FarisZR/caddy-dns-OCI/issues/2

**If you notice a plugin that is not listed in this project, open a [PR](#contributing)!**.

Are all plugins being built correctly?
This should be green, if it fails then something is not building correctly.

[![Main workflow](https://github.com/FarisZR/caddy-dns-OCI/actions/workflows/main-workflow.yml/badge.svg)](https://github.com/FarisZR/caddy-dns-OCI/actions/workflows/main-workflow.yml)

## usage

```bash
docker pull oci.fariszr.com/fariszr/caddy-dns:(YOURPLUGINNAME)
```
### Alpine

```bash
docker pull oci.fariszr.com/fariszr/caddy-dns:(YOURPLUGINNAME)-alpine
```

## Supported architectures
- AMD64
- ARM64
- ARMv7
- ARMv6


## Registries 
- `oci.fariszr.com` (Recommended, it's a redirect to [Quay.io](https://quay.io), and in the case of a new [rug pull](https://httptoolkit.com/blog/docker-image-registry-facade/), I can move to another host without changing the URL)
- GitHub packages (ghcr.io/FarisZR/caddy-dns)
- [docker hub](https://hub.docker.com/r/fariszr/caddy-dns)

## How does it work?
Glad you asked!
This is basically a CI project, relying on some quick scripts to check for remote pushes and versioning without any webhooks, which is possible because GitHub actions are unlimited for public repos (thanks Github!).

## Checking for caddy and plugin updates

### When there is a new caddy release
First, the `check-for-new-caddy-release` job will run, and use the GitHub API to compare the latest caddy release with the one in [caddy-release.txt](./git-hashes/caddy-release.txt).
If it is different, it will set the `caddy` output to true, which will trigger `update-caddy-build-version` to update the version in the repo.
Then the `check-for-plugin-updates` job will start, and since caddy itself is out of date, it will skip all plugin checks and set all plugins as out of date to force a rebuild.
(It will also trigger all builds if the `trigger_all_builds` input of a `workflow_dispatch` event is set to true).

### When a plugin is out of date
If Caddy is up to date, the `check-for-plugin-updates` job will use the [commit-check.sh](./commit-check.sh) script to fetch the latest remote commit and compare it with the hashes in the [git-hashes](./git-hashes/) folder.
If there is a new hash, it will set a plugin-specific output to true, which will then match the `if' expression for the build job for that specific plugin.

## Building images
Now that we know which images to update, we can start the build process.
Instead of adding all the steps to the [main-workflow.yml](.github/workflows/main-workflow.yml), which makes it incredibly difficult to manage, we use [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows).

This way we can just edit the file once and it will apply to all plugins, in addition to having no step details in the main workflow file.


The [start-build.yml](.github/workflows/start-build.yml) requires the following inputs: `dockerfile`, `dockerfile_alpine`, `image_title`, `license`, `tag`, `alpine_tag`, `go_plugin_link`, `hash_file`, `plugin_name`, `repo`.
then it calls [build-image.yml](.github/workflows/build-image.yml) using those inputs twice, once for the normal image and once for alpine.
and if the default build succeeds, it triggers the final job, `update-plugin-build-commit', which does what it says and updates the build hash for that plugin in [git-hashes](/git-hashes/).

## Contribute 
Thanks for your interest! as long as the project doesn't hit github's 256 job limit, it should be fine.

### Use this boilerplate for main-workflow.yml edits
Just replace all instances of `replaceme` with the repo name in the [caddy-dns](https://github.com/caddy-dns) org, and then paste them into the places mentioned in the comments.

```yaml
# new output in the `check-for-plugin-updates` job
      replacme: ${{ steps.replacme.outputs.replacme-out-of-date || steps.caddy-check.outputs.plugins-out-of-date }}
# new step in the `check-for-plugin-updates` job
      - name: Pull replacme plugin remote commits
        if: ${{ github.event.inputs.trigger_all_builds == 'false' || github.event.inputs.trigger_all_builds == '' && needs.check-for-new-caddy-release.outputs.caddy == 'false' }} #workaround, github inputs will be empty by default        
        id: replacme
        run: sh commit-check.sh https://github.com/caddy-dns/replacme replacme-local.txt git-hashes/replacme.txt replacme-out-of-date
# new job at the end of the file
  trigger-replacme-build:
    needs: check-for-plugin-updates
    if: ${{ needs.check-for-plugin-updates.outputs.replacme == 'true' }}
    uses: FarisZR/caddy-dns-OCI/.github/workflows/start-build.yml@main
    permissions:
      packages: write
      contents: write
    secrets: inherit
    with:
      dockerfile: Dockerfile
      dockerfile_alpine: Dockerfile-alpine
      image_title: Caddy with replacme dns plugin
      license: MIT
      tag: replacme
      alpine_tag: replacme-alpine
      go_plugin_link: github.com/caddy-dns/replacme
      hash_file: git-hashes/replacme.txt
      plugin_name: replacme
      repo: https://github.com/caddy-dns/replacme
```

### New hash file
Create an empty .txt file named after the upstream repos name in the [git-hashes](/git-hashes/) folder.
For example, the ovh plugins file is called `ovh.txt` because the repos name is `ovh`.