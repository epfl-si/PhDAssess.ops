#!/usr/bin/env nu

def all_from_zeebe_db_perl_importer [] {
  # Create columns
  | parse -r '\[(?P<columnFamily>\w+)\]\s(?P<ID>\d{16}):\s(?P<JSON>.*)'
  # filter to keep only needed data
  | where columnFamily in ['INCIDENTS', 'JOBS']
  # Parse the JSON part of the input
  | update JSON {|row| $row.JSON | from json }
}

def one_from_zeebe_db_perl_importer [
  processInstanceKey?: string
] {
  $in
  | where JSON.incidentRecord?.processInstanceKey? == $processInstanceKey
}

def main [
  snapshotTxtPath: path,  # The path to the snapshot stringified file. Should be the result of a ./phd.mjs stringify-snapshot
  processInstanceKey?: string  # Optional: if you want to filter for a specific instance
] {
  let zeebeData = open $snapshotTxtPath 
    | all_from_zeebe_db_perl_importer

  if $processInstanceKey != null {
    $zeebeData
    | ( 
      where JSON.incidentRecord?.processInstanceKey? == $processInstanceKey or JSON.jobRecord?.processInstanceKey? == $processInstanceKey
    )
  } else {
    $zeebeData
    | insert processInstanceKey {
      if ($in.JSON?.incidentRecord? != null) {
        $in.JSON.incidentRecord.processInstanceKey?
      } else if ($in.JSON?.jobRecord? != null) {
        $in.JSON.jobRecord.processInstanceKey?
      }
    }
    | group-by processInstanceKey
  }
}
