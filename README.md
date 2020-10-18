[![Build Status](https://travis-ci.org/deekayen/ansible-role-ivanti-heat.svg?branch=main)](https://travis-ci.org/deekayen/ansible-role-ivanti-heat) [![Project Status: Unsupported – The project has reached a stable, usable state but the author(s) have ceased all work on it. A new maintainer may be desired.](https://www.repostatus.org/badges/latest/unsupported.svg)](https://www.repostatus.org/#unsupported) ![BSD 3-Clause license](https://img.shields.io/badge/license-BSD%203--Clause-blue) ![Windows platform](https://img.shields.io/badge/platform-windows-lightgrey)

Ivanti HEAT
===========

Install [Ivanti HEAT](https://www.ivanti.com/company/history/heat-software) using a nuget package for Windows.

Requirements
------------

Microsoft Windows 2008+

Variable Defaults
-----------------

```
heat_serveraddress: "heat.example.com"
heat_modulelist: "VulnerabilityManagement"
```

Role Variables
--------------

```
chocolatey_source: https://nexus.example.com/repository/nuget-hosted/
```

Dependencies
------------

deekayen.chocolatey

Example Playbook
----------------

```
- hosts: platform_windows

  roles:
     - { role: deekayen.ivanti_heat }
```

Ivanti HEAT Agent Chocolatey Package Creation
------------------------------------

This package wraps the Ivanti HEAT Agent exe in a nuget package so that the win_chocolately Ansible module can install it.

### Pre-Tasks

1. Install chocolatey within your local PowerShell installation
2. Add your Nuget API key into your chocolatey configuration
`choco apikey -k MYKEY-COPIED-FROM-NEXUS-PROFILE https://nexus.example.com/repository/nuget-hosted/`
3. Download the agent installer msi and store it in the tools subfolder as the name dotNetAgentSteup.Msi
4. Update the ivanti-heat-agent.nuspec <version> element with the specific version of the agent downloads

### Create the package

1. Open PowerShell and navigate to the same folder where the .nuspec file exists
2. Run chocolatey pack command:
`choco pack`
3. You can test this package on a server by either running the the chocolatey commands manually or by using the win_chocolatey Ansible module manually, or through Ansible Tower/AWX adhoc commands.
4. Push the package to the nexus repo
`choco push .\Ivanti.HEAT.8.5.0.41.nupkg -source https://nexus.example.com/repository/nuget-hosted/`

### Package Arguments

The package takes to arguments which can be passed via Ansible params element on
the the win_chocolatey module

* `/HeatServerAddress:` - determines what server to point to for configuration - defaults to "heat.smartcorp.net"
* `/HeatModuleList:` - What modules to install - defaults to "VulnerabilityManagement"

