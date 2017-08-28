
from splunk_http_event_collector import http_event_collector
import json
import requests
hec = [
    {
        'itops': {
            'http_event_server': '10.209.1.13',
            'http_event_port': '5000',
            'token': 'E2668922-C50E-40A2-BAD7-CD16B291ECAE',
            'sourcetype': 'test_data_ucp_ucp',
            'name': 'itops'
        },
        'zero': {
            'http_event_server': 'sv3-prdv-splkx-508.sv.splunk.com',
            'http_event_port': '8088',
            'token': '09D4EA62-0139-4558-B690-2EE026677619',
            'sourcetype': 'test_data',
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
def splunk_data():
    hec_connection_list = []
    for hec_profile in hec:
        for hec_key, hec_values in hec_profile.items():
            hec_connection = http_event_collector(http_event_server=hec_values['http_event_server'],
                                                  http_event_port=hec_values['http_event_port'],
                                                  token=hec_values['token'],
                                                  sourcetype=hec_values['sourcetype'])
            hec_connection_list.append(hec_connection)
    for data in test:
        payload = {}
        payload.update({"event": json.dumps(data)})
        for hec_connection in hec_connection_list:
            hec_connection.batchEvent(payload)
            hec_connection.flushBatch()
if __name__ == '__main__':
    splunk_data()