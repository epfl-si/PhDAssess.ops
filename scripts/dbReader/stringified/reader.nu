###
# Transform the perl generated txt file from a zeebe db into nu structured data
###

def filter_out_useless_data [] {
    # INCIDENTS clear list
    | reject incidentRecord?.bpmnProcessId?
    | reject incidentRecord?.elementId?
    | reject incidentRecord?.elementInstanceKey?
    | reject incidentRecord?.jobKey?
    | reject incidentRecord?.processDefinitionKey?
    | reject incidentRecord?.variableScopeKey?
    # JOBS clear list
    | reject jobRecord?.bpmnProcessId?
    | reject jobRecord?.customHeaders?.formIO?
    | reject jobRecord?.deadline?
}

export def all_from_zeebe_db_perl_importer [
  extended?: bool = false # set to true to show all the data from the JSON
] {
  $in
  # Create columns
  | parse -r '\[(?P<columnFamily>\w+)\]\s(?P<Id>\d{16}):\s(?P<JSON>.*)'
  # filter to keep only needed data
  | where columnFamily in ['INCIDENTS', 'JOBS']
  # Parse the JSON part of the input
  | update JSON {
    |row| $row.JSON | from json
    | if $extended { $in } else { filter_out_useless_data }
  }
  | insert processInstanceKey {
    if ($in.JSON?.incidentRecord? != null) {
      $in.JSON.incidentRecord.processInstanceKey?
    } else if ($in.JSON?.jobRecord? != null) {
      $in.JSON.jobRecord.processInstanceKey?
    }
  }
}
