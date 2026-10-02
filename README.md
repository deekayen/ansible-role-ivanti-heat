# deekayen.ivanti_heat

[![CI](https://github.com/deekayen/ansible-role-ivanti-heat/actions/workflows/ci.yml/badge.svg)](https://github.com/deekayen/ansible-role-ivanti-heat/actions/workflows/ci.yml) [![Ansible Galaxy](https://img.shields.io/badge/galaxy-deekayen.ivanti__heat-blue.svg)](https://galaxy.ansible.com/ui/standalone/roles/deekayen/ivanti_heat/) [![Project Status: Unsupported – The project has reached a stable, usable state but the author(s) have ceased all work on it. A new maintainer may be desired.](https://www.repostatus.org/badges/latest/unsupported.svg)](https://www.repostatus.org/#unsupported) ![BSD 3-Clause license](https://img.shields.io/badge/license-BSD%203--Clause-blue)

An Ansible role that installs the Ivanti HEAT (EMSS) agent on Windows Server from a Chocolatey package hosted on your own NuGet feed, points it at a HEAT server, and starts the `EMSS Agent` service.

The role installs the `Ivanti.HEAT` package with `chocolatey.chocolatey.win_chocolatey` from `chocolatey_source`, passing `/HeatServerAddress` and `/HeatModuleList` as package parameters. Build the package from `ivanti-heat-agent.nuspec` and `tools/chocolateyInstall.ps1` in this repository and push it to your feed (see [Package build](#package-build)). The Galaxy name uses an underscore (`deekayen.ivanti_heat`), while the repository name uses a hyphen.

## Requirements

- ansible-core 2.15 or newer on the controller.
- The `ansible.windows` and `chocolatey.chocolatey` collections.
- A WinRM or SSH connection to the target with administrative rights.
- The `Ivanti.HEAT` package published to the NuGet feed at `chocolatey_source`, and network access from the target to that feed.
- If Chocolatey is not installed yet, network access from the target to `https://chocolatey.org/install.ps1`, which the `deekayen.chocolatey` dependency downloads and runs.
- A `become_user` for the `ansible.builtin.runas` become method. The install task sets `become: true` and `become_method` but no user, so set `ansible_become_user` in inventory.

## Supported platforms

| Platform | Versions |
| --- | --- |
| Windows | 2016, 2019, 2022 |

CI runs `ansible-lint` and `ansible-playbook --syntax-check` only.

## Installation

From Ansible Galaxy:

```bash
ansible-galaxy role install deekayen.ivanti_heat
ansible-galaxy collection install ansible.windows chocolatey.chocolatey
```

Or pin it in `requirements.yml`:

```yaml
---
roles:
  - name: deekayen.ivanti_heat
    src: https://github.com/deekayen/ansible-role-ivanti-heat.git
    scm: git
    version: main

collections:
  - name: ansible.windows
  - name: chocolatey.chocolatey
```

```bash
ansible-galaxy install -r requirements.yml
```

## Role variables

| Variable | Default | Description |
| --- | --- | --- |
| `chocolatey_source` | `https://nexus.example.com/repository/nuget-hosted/` | NuGet feed that hosts the `Ivanti.HEAT` package. Must start with `http://` or `https://`. The default is a placeholder; set it to your feed. |
| `heat_serveraddress` | `heat.example.com` | HEAT server the agent reports to, passed as `/HeatServerAddress`. Must be non-empty and contain no spaces. The default is a placeholder; set it to your server. |
| `heat_modulelist` | `VulnerabilityManagement` | HEAT modules to install, passed as `/HeatModuleList`. Must be non-empty. |

Both placeholder defaults pass the role's input checks in `tasks/assert.yml`, so the role does not stop you from running it with them. `vars/main.yml` holds the path to `lmagent.exe` that the role checks for an existing install.

## Behavior

- The role skips the install when `C:\Program Files\HEAT Software\EMSSAgent\01\lmagent.exe` exists. A host with any agent version there is left alone, so the role installs but does not upgrade.
- The `Start the EMSS agent.` handler sets the `EMSS Agent` service to start automatically and starts it. It runs only after a fresh install.
- The package install script accepts exit codes 0, 3010, and 1641. The role does not reboot the host.

## Dependencies

- `deekayen.chocolatey`, declared in `meta/main.yml`, installs Chocolatey when `choco.exe` is missing and adds it to the machine `PATH`.

## Example playbook

```yaml
---
- name: Install the Ivanti HEAT agent.
  hosts: windows_servers

  vars:
    chocolatey_source: https://nexus.example.internal/repository/nuget-hosted/
    heat_serveraddress: heat.example.internal
    ansible_become_user: System

  roles:
    - deekayen.ivanti_heat
```

`nexus.example.internal` and `heat.example.internal` are placeholders for your NuGet feed and HEAT server.

## Package build

The role expects an `Ivanti.HEAT` package on the feed. To build it from this repository on a Windows workstation with Chocolatey installed:

1. Copy the Ivanti agent installer into `tools/` as `lmsetupx64.exe`. `.gitattributes` routes `*.exe` and `*.nupkg` through Git LFS if you commit them.
2. Set `<version>` in `ivanti-heat-agent.nuspec` to the agent version. The file currently says `8.5.0.41`.
3. Pack the package from the repository root and push it to the feed:

```powershell
choco pack ivanti-heat-agent.nuspec
choco push Ivanti.HEAT.8.5.0.41.nupkg --source https://nexus.example.internal/repository/nuget-hosted/ --api-key YOUR-FEED-API-KEY
```

`tools/chocolateyInstall.ps1` runs `lmsetupx64.exe install SERVERADDRESS=<server> MODULELIST=<modules>`. Without package parameters it falls back to `heat.example.com` and `VulnerabilityManagement`. See the Chocolatey [pack](https://docs.chocolatey.org/en-us/create/commands/pack/) and [push](https://docs.chocolatey.org/en-us/create/commands/push/) command references.

## Tags

| Tag | Tasks |
| --- | --- |
| `always` | Input validation in `tasks/assert.yml`. |
| `install` | The `win_chocolatey` package install. |

## Development

CI runs on every push to `main` and every pull request (see `.github/workflows/ci.yml`). It installs the role and collections from `tests/requirements.yml`, runs `ansible-lint --profile production`, and syntax-checks `tests/test.yml`. To run the same checks locally:

```bash
pip3 install ansible-lint
ansible-galaxy install -r tests/requirements.yml
ansible-lint --profile production
mkdir -p .ansible/roles && ln -sfn "$PWD" .ansible/roles/deekayen.ivanti_heat
ANSIBLE_ROLES_PATH=.ansible/roles:~/.ansible/roles ansible-playbook --syntax-check tests/test.yml -i tests/inventory
```

The repository also has a `.pre-commit-config.yaml`; run `pre-commit run --all-files` before pushing.

### Repository layout

| Path | Purpose |
| --- | --- |
| `tasks/main.yml` | Input validation, existing-install check, and package install. |
| `tasks/assert.yml` | Checks the feed URL, server address, and module list. |
| `handlers/main.yml` | Starts the `EMSS Agent` service. |
| `defaults/main.yml` | Every user-facing variable. |
| `vars/main.yml` | Path to `lmagent.exe`. |
| `ivanti-heat-agent.nuspec` | Chocolatey package definition for `Ivanti.HEAT`. |
| `tools/chocolateyInstall.ps1` | Package install script that runs `lmsetupx64.exe`. |
| `tests/` | Syntax-check playbook, inventory, and test requirements used by CI. |

## Releases

Pushing a git tag runs `.github/workflows/release.yml`, which imports the tagged commit into Ansible Galaxy as `deekayen.ivanti_heat`. The import needs a `GALAXY_API_KEY` repository or organization secret.

## License

BSD 3-Clause. See [LICENSE](LICENSE).

## Author

[David Norman](https://github.com/deekayen). Sponsorship links are in [.github/FUNDING.yml](.github/FUNDING.yml).
