# Docker Neovim IDE

This is a Docker container that runs Neovim with development environments for different languages.

## Setup

1. Create `.env` with the username, UID and GID of the host user:
  ```
  USERNAME=
  USER_UID=
  USER_GID=
  GIT_AUTHOR_EMAIL=
  GIT_AUTHOR_NAME=
  ```
2. Use Stow to symlink the dotfiles for the corresponding language and zsh
3. Make sure that the correct dotfiles (from dotfiles repo) are mounted into the container in `docker-compose.yml`
4. Set the target in `docker-compose.yml` to the build stage that corresponds with the language
5. Optionally, change the name for the image and container or use different folders for different images/containers
6. Run `docker compose build && docker compose up -d`
7. Jump into container with `docker exec -it <container_name> zsh`

## To-do

This is very much a prototype so everything is subject to change.

- [ ] Automate process
  - [ ] Add option to choose image/container names
