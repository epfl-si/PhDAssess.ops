library(tidyverse)
library(jsonlite)
library(lubridate)
library(glue)
library(ggplot2)

tasks_journal <-
    glue::glue(r"(
       oc -n phd-assess exec -i services/mongo -- \
          mongo --quiet meteor --eval "printjson(db.tasks_journal.find().toArray());" \
       | grep -v '"msg"' | sed -e 's/ISODate(\(".*"\))/\1/' | jq -c '.[]'
    )") %>%
    pipe() %>%
    stream_in() %>%
    mutate(lastSeen = ymd_hms(lastSeen))

tasks_journal %>%
    ggplot(aes(x = lastSeen, y = seenCount)) +
    geom_point()
