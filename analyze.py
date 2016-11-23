#!/usr/bin/env python3

import csv
from collections import defaultdict
from statistics import median, mode, mean, stdev

def most_popular_routes(routes):
	occurrences = defaultdict(int)
	for route in routes:
		start = route["start"]
		end = route["end"]
		occurrences[start+"---"+end] += 1

	return sorted(occurrences.items(), key=lambda x: -x[1])[1:20]

def most_popular_stations(routes):
	occurrences = defaultdict(int)
	for route in routes:
		start = route["start"]
		end = route["end"]
		occurrences[start] += 1
		occurrences[end] += 1

	return sorted(occurrences.items(), key=lambda x: -x[1])[1:20]

def most_popular_start_hours(routes):
	occurrences = defaultdict(int)
	for route in routes:
		startHour = route["startTime"].split(':')[0]
		occurrences[startHour] += 1

	return sorted(occurrences.items(), key=lambda x: -x[1])[1:20]

def average_duration(routes):
	durations = []
	for route in routes:
		duration = route["duration"]
		durations.append(duration)

	return (mean(durations), median(durations), mode(durations), stdev(durations),)

def main():
	lines = []
	with open('textdata/AllTrips.csv', 'r') as f:
		reader = csv.reader(f, delimiter=';')
		for i, line in enumerate(reader):
			if i == 0:
				continue
			line = {
				"startDate": line[0],
				"startTime": line[1],
				"start": line[2],
				"startId": line[3],
				"endDate": line[4],
				"endTime": line[5],
				"end": line[6],
				"endId": line[7],
				"duration": float(line[8].replace(",", "."))
			}
			lines.append(line)

	print(most_popular_routes(lines))
	print(most_popular_stations(lines))
	print(most_popular_start_hours(lines))
	print(average_duration(lines))

if __name__ == "__main__":
	main()