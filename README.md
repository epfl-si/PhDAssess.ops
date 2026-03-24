# PhDAssess Ops

This repository regroups:
- `./phdsible`, the configuration-as-code to provision, configure, deploy, and manage the EPFL's PhDAssess stack
- `./phd.mjs`, a tool for cli operations
- `./scripts/` for some useful JS, Nushell, and perl scripts
- a `./HOWTO.md`, for some useful recipes
- a `./ARCHITECTURE.md`, to understand what is all about

# Configuration-as-code
Aka `phdsible`, the Ansible deployer

## Prerequisites

* Access to [Keybase] key folders : 
    * `/keybase/team/epfl_phdassess/dev/`
    * `/keybase/team/epfl_phdassess/test/`
    * `/keybase/team/epfl_phdassess/prod/`
* Access to the OpenShift.
* Some basic understanding of the stack. See [the architecture of the stack](ARCHITECTURE.md).

## Usage

`./phdsible`

Set up the development environment on Openshift and run the stack.

Add `--test` to do the same in the testing environment.
Add `--prod` to do the same in the production environment.

# DevOps locally

Use the cli `./phd.mjs`, or follow this steps:

## Understand

See `./ARCHITECTURE.md`

## Where to start?

How about launching the app locally?

### Zeebe

- Launch the Zeebe stack with:
    - `./phd.mjs zeebe start`
- Once Zeebe is running (`./phd.mjs zeebe status`, you can deploy the bpmn on it.
  You can use this command to help with the process:
    - `./phd.mjs zeebe deploy-bpmn`
- Once you start operating on it, you can see the processes on the operate app on `localhost:8082`

### Micro-services

- In the parent directory of this projet, clone the other services:
    - `cd ..`
    - `git clone https://github.com/epfl-si/phdAssess-PDF`
    - `git clone https://github.com/epfl-si/phdAssess-Notifier`
    - `git clone https://github.com/epfl-si/phdAssess-GED`
    - `git clone https://github.com/epfl-si/phdAssess-ISA`
- Come back into the projet folder
    - `cd PhDAssess`
- Build and start the services
    - `docker compose -f ./docker/docker-compose.yml build pdf notifier ged isa`
    - `docker compose -f ./docker/docker-compose.yml up pdf notifier ged isa`

## Run your frontend

Follow https://github.com/epfl-si/PhDAssess
