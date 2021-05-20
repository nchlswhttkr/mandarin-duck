# mandarin-duck [![Build status](https://badge.buildkite.com/e2e9dc24f63475920927734c9faab681d4606556fa25993eb4.svg)](https://buildkite.com/nchlswhttkr/mandarin-duck)

A tool to trigger Buildkite pipelines from a self-hosted Git repository.

_You can clone this repository from `https://nicholas.cloud/git/mandarin-duck.git`, but it's also mirrored to GitHub for convenience and issue tracking._

## Usage

You will need [`curl`](https://curl.se/) and [`jq`](https://stedolan.github.io/jq/) installed on your host server.

The installation script is currently user-specific, so you'll need to run it as the user you `git push` with. This is typically the `git` user.

The `install.sh` script takes one argument, the path to your self-hosted Git repository. This example uses `/srv/git/example-project.git`.

```sh
ssh git@example.com

git init --bare /srv/git/example-project.git # If your repo isn't already set up

git clone https://nicholas.cloud/git/mandarin-duck.git
cd mandarin-duck
./install.sh /srv/git/example-project.git/
```

The project is installed to your home directory (`~/.mandarin-duck/`), and a trigger is added to the `post-receive` hook of the target repository. You'll need to add some additional information to the `~/.mandarin-duck/mandarin-duck.cfg` configuration file.

| Name                                                               | Description                                                                     |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| `buildkite_api_token`                                              | [Your Buildkite API token](https://buildkite.com/docs/apis/managing-api-tokens) |
| `buildkite_organization_slug`                                      | The URL-friendly name of your Buildkite organization                            |
| `projects["/srv/git/example-project.git"].buildkite_pipeline_slug` | The URL-friendly name of this project's pipeline                                |

If you want to set up triggers for multiple Git repositories, re-run the `install.sh` for each project. They will each be added to your configuration file.

### Uninstall

There's a corresponding uninstall script to wipe all traces of `mandarin-duck` from your server. It deletes the triggers it's created in each repositiroy and then deletes itself.

```sh
ssh git@example.com
cd mandarin-duck
./uninstall.sh
cd ..
rm -rf mandarin-duck
```
