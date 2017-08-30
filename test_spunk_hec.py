import collections
import sys
from pprint import pprint

from splunk_http_event_collector import http_event_collector
import json
import requests

hec = [
	{
		'itops': {
			'http_event_server': '10.209.1.13',
			'http_event_port': '5000',
			'token': 'E2668922-C50E-40A2-BAD7-CD16B291ECAE',
			'sourcetype': 'test_data_ucp',
			'name': 'itops'
		},
		'zero': {
			'http_event_server': 'sv3-prdv-splkx-508.sv.splunk.com',
			'http_event_port': '8088',
			'token': '09D4EA62-0139-4558-B690-2EE026677619',
			'sourcetype': 'test_data_ucp',
			'name': 'zero'
		},
	}]
test = [{
	"groupname": "UCPProd",
	"priority": "1",
	"node_status": "UP",
	"node_color": "lime",
	"ssh_status": "UP",
	"ssh_color": "lime",
	"telnet_status": "UP",
	"telnet_color": "lime",
	"dockerps_status": "UP",
	"dockerps_color": "lime",
	"overlay_status": "UP",
	"overlay_color": "green",
	"freeMem_status": "3",
	"freeMem_color": "",
	"service_status": "",
	"service_color": "",
	"container_count": ""
},
	{
		"groupname": "UCPProd",
		"priority": "1",
		"node_status": "UP",
		"node_color": "lime",
		"ssh_status": "UP",
		"ssh_color": "lime",
		"telnet_status": "UP",
		"telnet_color": "lime",
		"dockerps_status": "UP",
		"dockerps_color": "lime",
		"overlay_status": "UP",
		"overlay_color": "green",
		"freeMem_status": "3",
		"freeMem_color": "UP",
		"service_status": "green",
		"service_color": "3",
		"container_count": ""
	},
	{
		"groupname": "UCPProd",
		"priority": "1",
		"node_status": "UP",
		"node_color": "lime",
		"ssh_status": "UP",
		"ssh_color": "lime",
		"telnet_status": "UP",
		"telnet_color": "lime",
		"dockerps_status": "UP",
		"dockerps_color": "lime",
		"overlay_status": "UP",
		"overlay_color": "green",
		"freeMem_status": "3",
		"freeMem_color": "UP",
		"service_status": "UP",
		"service_color": "green",
		"container_count": "3"
	}
]


def get_sample_data():
	results = requests.get('http://ad.api.itops.splunk.com/splunkcorp/users/peterc')
	results_dict = json.loads(results.text)
	return results_dict


def read_file(filename):
	with open(filename, 'r') as file:
		file_data = file.read()
		file_dict = json.loads(file_data)
	pprint(file_data)
	splunk_data(file_dict)


def flatten(d, parent_key='', sep='_'):
	items = []
	for k, v in d.items():
		new_key = parent_key + sep + k if parent_key else k
		if isinstance(v, collections.MutableMapping):
			items.extend(flatten(v, new_key, sep=sep).items())
		else:
			v = None if v is u'' else v
			if 'critical' not in new_key and 'warning' not in new_key and 'label' not in new_key and v is not None:
				key_name = new_key.replace('perf_perf_', 'perf_')
				items.append((key_name.lower(), v.lower()))
	return dict(items)


def splunk_data(file_dict):
	hec_connection_list = []
	for hec_profile in hec:
		for hec_key, hec_values in hec_profile.items():
			hec_connection = http_event_collector(http_event_server=hec_values['http_event_server'],
												  http_event_port=hec_values['http_event_port'],
												  token=hec_values['token'],
												  sourcetype=hec_values['sourcetype'])
			hec_connection_list.append(hec_connection)
	for key, data in file_dict.items():
		payload = {}
		components = data.get('components')
		if not components:
			continue
		for component in components:
			new_payload = {}
			components_flattened = flatten(component,'component')
			for key, value in data.items():
				if not 'components' in key:
					new_payload[key.lower().strip()] = value.strip().lower()
			new_payload.update(components_flattened)
			payload.update({"event": json.dumps(new_payload)})
			for hec_connection in hec_connection_list:
				hec_connection.batchEvent(payload)
			for hec_connection in hec_connection_list:
				hec_connection.flushBatch()
		for hec_connection in hec_connection_list:
			hec_connection.flushBatch()


if __name__ == '__main__':
	# filename=sys.argv[1]
	filename = 'health_json.json'
	read_file(filename)
