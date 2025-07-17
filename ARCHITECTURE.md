# Architecture

This document describes the high-level architecture of the PhD assess applications, 
if you want to familiarize yourself with the stack.

## Zeebe

This application is responsible for advancing the process through the BPMN paths and to keep the data while the process is active.

#### Components
- gateway
- brokers

These two are mixed in the same Docker image.

## Zeebe Clients 

These are the workers as Microservices, using Node.js and TypeScript.

| Worker as microservice | Role                                  | Repo                                          |
|------------------------|---------------------------------------|-----------------------------------------------|
| PhDAssess              | Serve the forms and offer a dashboard | https://github.com/epfl-si/PhDAssess          |
| PhDAssess-PDF          | Build the PDF                         | https://github.com/epfl-si/PhDAssess-PDF      |
| PhDAssess-GED          | Deposit on GED                        | https://github.com/epfl-si/PhDAssess-GED      |
| PhDAssess-Notifier     | Send emails                           | https://github.com/epfl-si/PhDAssess-Notifier |
| PhDAssess-ISA          | Post results in ISA                   | https://github.com/epfl-si/PhDAssess-ISA      |

## Data

### PhDAssess-meta

[The repository](https://github.com/epfl-si/PhDAssess-meta) defines the flow of events (BPMN) and the variables in use through a shared TypeScript types definition.
