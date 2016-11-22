Sys.setlocale("LC_ALL", locale="no_NO")

require(lubridate)
require(caret)
require(xgboost)
require(data.table)
require(Matrix)
require(dplyr)

trips_allCols <- read.csv("AllTrips.csv", sep=";", dec=",")
load('availability_edited') # Herfra får vi avail_orig
stations <- distinct(avail_orig, name, lat, lon, masl)
stations <- transmute(stations, Station=name, Latitude=lat, Longitude=lon, Altitude=masl)

trips <- select(trips_allCols, StartStation, EndStation, Duration)
#trips <- mutate(trips, AverageDuration = mean(Duration), Journey = paste(StartStation, "---", EndStation))

# Antall ganger en reise (med retning) er blitt utført
trip_counts <- tally(group_by(trips, StartStation, EndStation))
mutate(left_join(trip_counts, stations, by=c("StartStation", "Station")), StartLatitude=Latitude, StartLongitude=Longitude)

from_counts <- tally(group_by(trips, StartStation))
from_counts <- transmute(from_counts, Station=StartStation, nStart=n)
to_counts <- tally(group_by(trips, EndStation))
to_counts <- transmute(to_counts, Station=EndStation, nEnd=n)
both_counts <- full_join(from_counts, to_counts, by="Station")

# Antall besøk på hver stasjon
station_counts <- transmute(both_counts, Station=Station, n=nStart+nEnd)