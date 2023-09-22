#!/usr/bin/env nu

use reader.nu all_from_zeebe_db_perl_importer

def main [
  snapshotTxtPath: path,  # The path to the snapshot stringified file. Should be the result of a ./phd.mjs stringify-snapshot
  processInstanceKey?: string  # Optional: if you want to filter for a specific instance
  --compact  # to remove any JSON details
] {
  let zeebeData = open $snapshotTxtPath | all_from_zeebe_db_perl_importer

  if $processInstanceKey != null {
    $zeebeData
    | where processInstanceKey? == $processInstanceKey
  } else {
    $zeebeData
  }
  | if $compact { reject JSON } else { $in }
  # here we change the structure to have a view per Instance
  | group-by processInstanceKey
}
