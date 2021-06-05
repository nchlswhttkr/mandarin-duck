# mandarin-duck [![Build status](https://badge.buildkite.com/e2e9dc24f63475920927734c9faab681d4606556fa25993eb4.svg)](https://buildkite.com/nchlswhttkr/mandarin-duck)

A tool to trigger Buildkite pipelines from a self-hosted Git repository.

_You can clone this repository from `https://nicholas.cloud/git/mandarin-duck.git`, but it's also mirrored to GitHub for convenience and issue tracking._

## Usage

You will need [`curl`](https://curl.se/) and [`jq`](https://stedolan.github.io/jq/) installed on your host server.

The `install.sh` script is currently user-specific, so you'll need to run it as the user you `git push` with. This is typically the `git` user.

You can provide the paths to your self-hosted Git repositories to the install script as arguments. This example uses one repo, `/srv/git/example-project.git`.

```sh
ssh git@example.com

git init --bare /srv/git/example-project.git # If your repo isn't already set up

git clone --branch v1.1 https://nicholas.cloud/git/mandarin-duck.git
cd mandarin-duck
./install.sh /srv/git/example-project.git/
```

The project is installed to your home directory (`~/.mandarin-duck/`), and a trigger is added as the `post-receive` hook of each repository. You'll need to add some additional information to the `~/.mandarin-duck/mandarin-duck.cfg` configuration file.

| Name                                                               | Description                                                                 |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| `buildkite_api_token`                                              | [Your Buildkite API token](https://buildkite.com/user/api-access-tokens) \* |
| `buildkite_organization_slug`                                      | The URL-friendly name of your Buildkite organization                        |
| `projects["/srv/git/example-project.git"].buildkite_pipeline_slug` | The URL-friendly name of this project's pipeline                            |

\* You should create a new API token specifically for this project, and give it the [`write_builds` scope](https://buildkite.com/docs/apis/managing-api-tokens#token-scopes) to trigger builds.

If you want to set up triggers for multiple Git repositories, re-run the `install.sh` for each project. They will each be added to your configuration file.

### Upgrade

To upgrade, you can re-run the `install.sh` script. It will update the existing config, and make any necessary changes to your projects.

```sh
ssh git@example.com

cd mandarin-duck
git fetch --tags
git tag # find the latest verson
git checkout $LATEST_VERSION
./install.sh
```

### Uninstall

There's a corresponding uninstall script to wipe all traces of `mandarin-duck` from your server. It deletes the triggers it's created in each repositiroy, revokes the API token it's been using, and then deletes itself.

```sh
ssh git@example.com

cd mandarin-duck
./uninstall.sh

# clean up the source code too
cd ..
rm -rf mandarin-duck
```

## Releases

### v1.1

For a full list of commits and changes, see the [diff on GitHub](https://github.com/nchlswhttkr/mandarin-duck/compare/v1.0...v1.1).

- The Buildkite API token stored in config will be automatically revoked on uninstall.
- Using the [`[skip ci]`/`[ci skip]` keyword](https://buildkite.com/docs/pipelines/ignoring-a-commit) in a commit will prevent a build being triggered.
- Builds will no longer be triggered on deleted branches.
- You can automatically upgrade by running `./install.sh`!

### v1.0

Initial release. Hello world!
