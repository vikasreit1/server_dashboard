'''Example of pushing data to multiple Splunk HEC destinations'''
from  splunk_http_event_collector import http_event_collector
import json
import requests

hec = [
    {
        'itops': {
            'http_event_server': '10.209.1.13',
            'http_event_port': '5000',
            'token': '049927E1-206F-4C16-89B5-FFDEB1283569',
            'sourcetype': 'test_data_ucp',
            'name': 'itops'
        },
        'zero': {
            'http_event_server': 'sv3-prdv-splkx-508.sv.splunk.com',
            'http_event_port': '8088',
            'token': 'E328574A-CAB5-4C7B-A8AC-F6D34ABC764B',
            'sourcetype': 'test_data_ucp',
            'name': 'zero'
        },
    }]


def get_sample_data():
    results = requests.get('http://ad.api.itops.splunk.com/splunkcorp/users/nlowe')
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

    for key,value in get_sample_data().items():
        data_to_send = {}
        data_to_send[key]=value
        payload = {}
        payload.update({"event": json.dumps(data_to_send)})
        for hec_connection in hec_connection_list:
            hec_connection.batchEvent(payload)
    for hec_connection in hec_connection_list:
        hec_connection.flushBatch()

if __name__ == '__main__':
    splunk_data()