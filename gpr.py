#!/usr/bin/env python3

import numpy as np
import pandas as pd
import scipy
import math
import csv

from sklearn import linear_model, metrics, ensemble, tree, model_selection, gaussian_process, preprocessing

def split_dataset(dataset, proportion):
	mask = np.random.rand(len(dataset)) < proportion
	train = dataset[mask]
	test = dataset[~mask]
	return train, test

def extract_predictors_response(dataset, response_column_names, drop_other_columns=[]):
	predictors = dataset.drop(response_column_names, axis=1)
	predictors = dataset.drop(drop_other_columns, axis=1)
	response = dataset[response_column_names].set_index(np.arange(len(predictors)))
	return predictors, response

def mae(reference_resp, predicted_resp):
	return metrics.mean_absolute_error(reference_resp, predicted_resp)

def mse(reference_resp, predicted_resp):
	return metrics.mean_squared_error(reference_resp, predicted_resp)

def dataframe_from_number(number, length, column_names, index=None):
	if index is None:
		index = np.arange(length)
	return pd.DataFrame(number, index=index, columns=column_names)

def summarize(training_resp, reference_resp, predicted_resp):
	print(reference_resp - predicted_resp)
	print("MAE between reference and predicted: " + str(mae(reference_resp, predicted_resp)))
	print("MSE between reference and predicted: " + str(mse(reference_resp, predicted_resp)))

def do_gaussianprocess(training_pred, training_resp, test_pred, test_resp, normalize_y=True):
	kernel = gaussian_process.kernels.RBF()
	reg_gp = gaussian_process.GaussianProcessRegressor(kernel=kernel, normalize_y=normalize_y, alpha=1e-8)
	reg_gp.fit(training_pred, training_resp)
	predicted_resp_gp = reg_gp.predict(test_pred)

	print("Summary for Gaussian process regression")
	summarize(training_resp, test_resp, predicted_resp_gp)
	return predicted_resp_gp

def main():
	data = pd.read_csv('textdata/MungedTrips.csv')
	#data = pd.get_dummies(data)

	data_training, data_test = split_dataset(data, 0.7)
	print(len(data_training))
	print(len(data_test))

	training_pred, training_resp = extract_predictors_response(data_training, ['end_lat', 'end_lon'], ['start_station'])
	test_pred, test_resp = extract_predictors_response(data_test, ['end_lat', 'end_lon'], ['start_station'])

	do_gaussianprocess(training_pred, training_resp, test_pred, test_resp, normalize_y=False)

main()