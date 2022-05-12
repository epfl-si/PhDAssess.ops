library(tidyverse)
library(jsonlite)
library(lubridate)
library(glue)
library(ggplot2)

get_tasks_journal_cmd <- function(namespace) {
    glue::glue(r"(
       oc -n { namespace } exec -i services/mongo -- \
          mongo --quiet meteor --eval "printjson(db.tasks_journal.find().toArray());" \
       | grep -v '"msg"' | sed -e 's/ISODate(\(".*"\))/\1/' | jq -c '.[]'
    )")
}

get_tasks_journal <- function(namespace) {
    get_tasks_journal_cmd(namespace) %>%
        pipe() %>%
        stream_in() %>%
        mutate(lastSeen = ymd_hms(lastSeen))
}

tasks_journal <- get_tasks_journal(namespace = "phd-assess")

tasks_journal %>%
    ggplot(aes(x = lastSeen, y = seenCount)) +
    geom_point() +
    scale_y_log10()
