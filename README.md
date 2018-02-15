# Docker & Ruby Boilerplate

This repo contains bolierplate for Docker & Ruby applications. It uses
`make` and `docker-compose` to orchestrate the build and TDD process.
See the [SlashDeploy blog][blog] for more information.

## Usage

1. Download/clone this repo for your project
1. Set the image name in `docker-compose.yml`
1. Remove `Gemfile.lock` from `.gitignore`
1. Replace `vendor/cache` with `!vendor/cache` in `.gitignore`. This
   line ensures `vendor/cache` is committed to source control.
1. (Optional) remove `.gitlab-ci.yml` if you're not using GitLab.
1. Run `make clean test-ci` -- things should pass!
1. Start coding!
1. Run `make test` -- things should still pass!
1. Run `make clean test-ci` to review all changes

## Structure

The `docker-compose.yml` manages containers for the development and
test cycle. The `app` container uses the image that would eventually
go to production. The `tests` container is for running quick tests.
The source code directory is mounted as a local volume so there's no
need to rebuild the image to run tests. The `smoke` container executes
a smoke test against the `app` container.

[blog]: http://blog.slashdeploy.com/2016/05/02/docker_and_ruby_for_tdd_and_deployment/
