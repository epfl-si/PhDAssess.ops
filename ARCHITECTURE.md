# Architecture

This document describes the high-level architecture of the PhD assess applications, 
if you want to familiarize yourself with the stack.

## Zeebe

This application is responsible for advancing the process through the BPMN paths and keep the data while the process is active.

#### Components
- gateway
- brokers

These two are mixed in the same Docker image.

## Zeebe Clients 

This are the workers as Microservice. They are in Node.js and Typescript, mainly.

| Worker as microservice | Role                | Repo                                            |
|---|---|---|
| PhDAssess | Serve the forms and offer a dasbhoard | https://github.com/epfl-si/PhDAssess            |
| PhDAssess-PDF | Build the PDF                     | https://github.com/epfl-si/PhDAssess-PDF        |
| PhDAssess-GED | Deposit on GED                    | https://github.com/epfl-si/PhDAssess-GED        |
| PhDAssess-Notifier | Send emails                  | https://github.com/epfl-si/PhDAssess-Notifier   |
| PhDAssess-ISA | Post results in ISA               | https://github.com/epfl-si/PhDAssess-ISA        |

## Data

### PhDAssess-meta

[The repository](https://github.com/epfl-si/PhDAssess-meta) defines the flow of events (BPMN) and the variables in use through a shared Typescript types definition.
