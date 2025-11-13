#!/usr/bin/env nu

def main [
  snapshotPath: path,  # The path to the snapshot directory, where the .sst files are
  processInstanceKey?: int  # Optional: if you want to filter for a specific instance
] {

  let incidents_list = ^zdb incident list -p $snapshotPath | from json

  let optionaly_filtered_by_processInstanceKey = if $processInstanceKey != null {
    $incidents_list | where processInstanceKey == $processInstanceKey
  } else {
    $incidents_list
  }

  $optionaly_filtered_by_processInstanceKey
  | reject bpmnProcessId processDefinitionKey jobKey variablesScopeKey elementInstanceKey
  | insert type 'Incident' | move type --before key
  | group-by errorMessage
}
