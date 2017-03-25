#!/usr/bin/env python3

import numpy as np
import pandas as pd
import scipy
import math
import csv

from datetime import datetime

def munge(row, stations):
	StartDate = row[0]
	StartTime = row[1]
	StartStation = row[2].strip().replace('\n', ' ')
	StartStationId = row[3]
	EndDate = row[4]
	EndTime = row[5]
	EndStation = row[6].strip().replace('\n', ' ')
	EndStationId = row[7]
	Duration = row[8]

	if str(StartStation) == 'nan':
		return

	start_station = stations[StartStation]
	end_station = stations[EndStation]

	startTime = datetime.strptime(StartTime, '%H:%M:%S')
	timeSinceMidnight = (startTime - startTime.replace(hour=0, minute=0, second=0, microsecond=0)).total_seconds()
	timeSinceMidnight_periodic_x = math.sin(2*math.pi*(timeSinceMidnight/7))
	timeSinceMidnight_periodic_y = math.cos(2*math.pi*(timeSinceMidnight/7))

	weekday = datetime.strptime(StartDate, '%d/%m/%y').weekday()
	weekday_periodic_x = math.sin(2*math.pi*(weekday/7))
	weekday_periodic_y = math.cos(2*math.pi*(weekday/7))
	weekend = 0
	if weekday == 5 or weekday == 6:
		weekend = 1
	
	return [
		weekday_periodic_x,
		weekday_periodic_y,
		weekend,
		timeSinceMidnight_periodic_x,
		timeSinceMidnight_periodic_y,
		StartStation,
		#EndStation,
		Duration,
		start_station['lat'],
		start_station['lon'],
		start_station['masl'],
		start_station['total_locks'],
		end_station['lat'],
		end_station['lon'],
		end_station['masl'],
		end_station['total_locks']
	]

def main():
	stations_ = pd.read_csv('textdata/stations.csv').to_records(index=False)
	stations = {s.name.strip().replace('\n', ' '): { 'id': s.id, 'lat': s.lat, 'lon': s.lon, 'masl': s.masl, 'total_locks': s.total_locks} for s in stations_}

	data_ = pd.read_csv('textdata/AllTrips.csv', sep=";", decimal=",").to_records(index=False)
	data = []
	for d in data_:
		try:
			munged_d = munge(d, stations)
			data.append(munged_d)
		except Exception as e:
			continue
	
	with open('textdata/MungedTrips.csv', 'w') as f:
		field_names = ['weekday_x', 'weekday_y', 'weekend', 'time_x', 'time_y', 'start_station', 'duration', 'start_lat', 'start_lon', 'start_masl', 'start_total_locks', 'end_lat', 'end_lon', 'end_masl', 'end_total_locks']
		writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
		writer.writerow(field_names)
		for row in data:
			if row is None:
				continue
			writer.writerow(row)

main()