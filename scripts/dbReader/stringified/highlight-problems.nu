#!/usr/bin/env nu

use reader.nu all_from_zeebe_db_perl_importer

def keep_only_instances_having_at_least_an_incident_but_no_job [] {
  $in
  | transpose processInstanceKey columnFamiliesEntries
  | update columnFamiliesEntries { $in | reject processInstanceKey }
  | filter {
    $in.columnFamiliesEntries | all { $in.columnFamily == 'INCIDENTS' }
  }
}

def to_zeebe_resolve_incident_txt [
] {
  $in
  | each { |processInstance|
    print $"zbctl cancel instance ($processInstance.processInstanceKey) --insecure"
  }
  | ignore  ## don't show last table, it may be empty
}

def main [
  snapshotTxtPath: path  # The path to the snapshot stringified file. Should be the result of a ./phd.mjs stringify-snapshot  
  --compact  # should remove JSON details from the incidents/jobs ?    
  --to_zeebe_command  # should we print the command to clear the instances ?
] {
  open $snapshotTxtPath
  | all_from_zeebe_db_perl_importer
  | if ($compact or $to_zeebe_command) { reject JSON } else { $in }
  | group-by processInstanceKey
  | keep_only_instances_having_at_least_an_incident_but_no_job
  | if $to_zeebe_command { to_zeebe_resolve_incident_txt } else { $in }
}
