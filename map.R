Sys.setlocale("LC_ALL", locale="no_NO.UTF-8")

require(lubridate)
require(caret)
require(xgboost)
require(data.table)
require(Matrix)
require(dplyr)

trips_allCols <- read.csv("AllTrips.csv", sep=";", dec=",")
load('availability_edited') # Herfra får vi avail_orig
stations <- distinct(avail_orig, name, lat, lon, masl)
stations <- transmute(stations, Station=enc2utf8(trimws(name)), Latitude=lat, Longitude=lon, Altitude=masl)

trips <- select(trips_allCols, StartStation, EndStation, Duration)
trips <- mutate(trips, StartStation=enc2utf8(trimws(StartStation)), EndStation=enc2utf8(trimws(EndStation)))
trips <- filter(trips, StartStation != "", EndStation != "")

trip_counts <- tally(group_by(trips, StartStation, EndStation))
trip_counts <- mutate(left_join(trip_counts, stations, by=c("StartStation" = "Station")), StartLatitude=Latitude, StartLongitude=Longitude)
trip_counts <- select(trip_counts, -(Latitude:Altitude))
trip_counts <- mutate(left_join(trip_counts, stations, by=c("EndStation" = "Station")), EndLatitude=Latitude, EndLongitude=Longitude)
# Antall ganger en reise (med retning) er blitt utført, med koordinater for stasjonene
trip_counts <- select(trip_counts, -(Latitude:Altitude))

from_counts <- tally(group_by(trips, StartStation))
from_counts <- transmute(from_counts, Station=StartStation, nStart=n)
to_counts <- tally(group_by(trips, EndStation))
to_counts <- transmute(to_counts, Station=EndStation, nEnd=n)
both_counts <- full_join(from_counts, to_counts, by="Station")

# Antall besøk på hver stasjon
station_counts <- transmute(both_counts, Station=trimws(Station), n=nStart+nEnd)
station_counts <- filter(station_counts, Station != "")
station_counts <- mutate(left_join(station_counts, stations, by="Station"))