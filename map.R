Sys.setlocale("LC_ALL", locale="no_NO.UTF-8")

require(lubridate)
require(caret)
require(xgboost)
require(data.table)
require(ggmap)
require(Matrix)
require(dplyr)

trips_allCols <- read.csv("textdata/AllTrips.csv", sep=";", dec=",")
load('bindata/availability_edited') # Herfra får vi avail_orig
stations <- distinct(avail_orig, name, lat, lon, masl)
stations <- transmute(stations, Station=enc2utf8(trimws(name)), Latitude=lat, Longitude=lon, Altitude=masl)

trips <- select(trips_allCols, StartStation, EndStation, Duration)
trips <- mutate(trips, StartStation=enc2utf8(trimws(StartStation)), EndStation=enc2utf8(trimws(EndStation)))
trips <- filter(trips, StartStation != "", EndStation != "")

trip_counts <- tally(group_by(trips, StartStation, EndStation))
trip_counts <- mutate(left_join(trip_counts, stations, by=c("StartStation" = "Station")), StartLatitude=Latitude, StartLongitude=Longitude)
trip_counts <- select(trip_counts, -(Latitude:Altitude))
trip_counts <- mutate(left_join(trip_counts, stations, by=c("EndStation" = "Station")), EndLatitude=Latitude, EndLongitude=Longitude)
# Antall ganger en reise (med retning) er blitt utført, med koordinater for stativene
trip_counts <- select(trip_counts, -(Latitude:Altitude))

# De mest populære rutene mellom to ulike stativer
top_trip_counts <- arrange(filter(trip_counts, StartStation != EndStation), desc(n))[1:100,]

from_counts <- tally(group_by(trips, StartStation))
from_counts <- transmute(from_counts, Station=StartStation, nStart=n)
to_counts <- tally(group_by(trips, EndStation))
to_counts <- transmute(to_counts, Station=EndStation, nEnd=n)
both_counts <- full_join(from_counts, to_counts, by="Station")

# Antall besøk på hvert stativ
station_counts <- transmute(both_counts, Station=trimws(Station), n=nStart+nEnd)
station_counts <- filter(station_counts, Station != "")
station_counts <- mutate(left_join(station_counts, stations, by="Station"))

# Kartgenerering: Prikker for hvert stativ med størrelse og farge etter hvor mange som henter/leverer sykkel

plot <- qmplot(Longitude, Latitude, data = station_counts, maptype = "toner-lite", color = n, size = n) + scale_radius()
plot <- plot + scale_size_area(name="Antall turer fra/til") + scale_colour_continuous(low=60, high=5, guide=FALSE)
# og en strek for hver av de 100 mest populære rutene
#plot <- plot + geom_segment(data=top_trip_counts, aes(x=StartLongitude, y=StartLatitude, xend=EndLongitude, yend=EndLatitude, size=150), show.legend=FALSE, arrow = arrow(length = unit(0.01, "npc")))
print(plot)
