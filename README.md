# DevTools for Pterodactyl (custom image)

The previous LinuxServer Webtop image cannot launch under regular Pterodactyl permissions because its s6 init expects ownership of /run. This image avoids that root-init requirement.

## GitHub
1. Create a GitHub repository and upload `Dockerfile`, `start.sh` and `.github/workflows/docker.yml` preserving paths.
2. GitHub -> Actions -> Build DevTools image -> Run workflow (or push to `main`).
3. In GitHub Packages, set the published container package visibility to **Public** so Pterodactyl can pull it without credentials.
4. In `egg-ipad-devtools-custom.json` replace `USERNAME` in `docker_images` with your lower-case GitHub account or organization name, then import the egg into your nest.
5. In the Pterodactyl admin server settings choose the new egg; select the GHCR image, set a password under Startup, and start the server. The web desktop listens on the primary allocated port (`SERVER_PORT`).
6. Access `http://YOUR-HOST:YOUR-ALLOCATION/vnc.html?autoconnect=1&resize=scale` only through a secured HTTPS reverse proxy or VPN; the direct HTTP address is not appropriate for logging into personal accounts.

## Notes
- Empty Files tab is expected: program files are inside the Docker image, not `/home/container`.
- Pterodactyl cannot build an arbitrary Dockerfile merely by importing an egg JSON. You must publish the image first.
- Chromium is started with `--no-sandbox` to run in this constrained environment; do not browse untrusted websites or expose this desktop publicly.
- The package has not been tested on your Wings installation. Some Wings resource/seccomp configurations may need adjustments.
