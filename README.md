# mandarin-duck [![Build status](https://badge.buildkite.com/e2e9dc24f63475920927734c9faab681d4606556fa25993eb4.svg)](https://buildkite.com/nchlswhttkr/mandarin-duck)

A tool to trigger Buildkite pipelines from a self-hosted Git repository.

<!-- TODO: Handle tag pushing - how is this represented? -->
<!-- TODO: Move to self-hosted repository, clarify that GitHub is a mirror -->
<!-- TODO: Support [skip ci] - or maybe leave to Buildkite? -->

## Usage

You will need [`curl`](https://curl.se/) and [`jq`](https://stedolan.github.io/jq/) installed on your host server.

The installation script is currently user-specific, so you'll need to run it as the user you intend to `git push` as. This is typically the `git` user.

The `install.sh` script takes one argument, the path to your self-hosted Git repository. This example uses `/srv/git/example-project.git`.

```sh
ssh git@example.com

git init --bare /srv/git/example-project.git # If your repo isn't already set up

git clone https://nicholas.cloud/git/mandarin-duck.git
cd mandarin-duck
./install.sh /srv/git/example-project.git/
```

This creates a `post-receive` hook in the target repository and a configuration file at `~/.mandarin-duck/mandarin-duck.cfg`. You'll need to fill out this file with some general and project-specific information.

| Name                                                               | Description                                          |
| ------------------------------------------------------------------ | ---------------------------------------------------- |
| `buildkite_api_token`                                              | Your Buildkite API token                             |
| `buildkite_organization_slug`                                      | The URL-friendly name of your Buildkite organization |
| `projects["/srv/git/example-project.git"].buildkite_pipeline_slug` | The URL-friendly name of this project's pipeline     |

If you want to set up triggers for multiple Git repositories, re-run the `install.sh` for each project. They will each be added to your configuration file.

<!-- TODO: How to upgrade -->

<!-- TODO: How to uninstall -->
