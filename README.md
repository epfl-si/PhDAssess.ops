# PhDAssess Ops

This repository regroups the configuration-as-code to provision, configure,
deploy and manage the EPFL's PhDAssess stack. It uses Ansible wrapped in a
convenient [suitcase](https://github.com/epfl-si/ansible.suitcase), called [phdsible](./ansible/phdsible).

## Prerequisites

* Access to [Keybase] key folders : 
    * `/keybase/team/epfl_phdassess/dev/`
    * `/keybase/team/epfl_phdassess/test/`
    * `/keybase/team/epfl_phdassess/prod/`
* Access to the OpenShift.
* Some basic understanding of [the architecture of the stack](ARCHITECTURE.md)

## Usage

`./ansible/phdsible`

Setup the dev. environment on Openshift and run the stack.

Use `--prod` to do the same in the production environment.
