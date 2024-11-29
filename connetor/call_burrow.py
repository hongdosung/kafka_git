import requests
import json
from datetime import datetime

class Burrow():
    def __init__(self):
        self.cluster_nm = 'xxx_kafka'
        self.http_endpoint = f'http://xxxpmst01:8000/v3/kafka{self.cluster_nm}'
    
    def get_consumer_status(self):
        rspt_dict = requests.get(f'{self.http_endpoint}/consumer').json()
        consumer_lst = rspt_dict['consumers']
        for consumer in consumer_lst:
            rslt = self.get_warn_err_consumer(consumer)
            if rslt:
                topic = rslt[0]
                status = rslt[1]
                start_lag = rslt[2]
                start_ts = rslt[3]
                end_lag = rslt[4]
                end_ts = rslt[5]
                
                msg = f'''Consumer Lag 발생 Alram
- Consumer Group명: {consumer}
- TOPIC: {topic}
- status: {status}
- start lag: {start_lag}
- start time: {start_ts}
- end lag: {end_lag}
- end time: {end_ts}'''
                print(msg)

    
    def get_warn_err_consumer(self, consumer):
        status_dict = requests.get(f'{self.http_endpoint}/consumer/{consumer}/status').json().get('status')
        status = status_dict['status']
        if status in ['WARN', 'ERR', 'STOP:', 'STALL']:
            status_maxlag = status_dict.get('maxlag')
            start_info = status_maxlag.get('start')
            end_info = status_maxlag.get('end')
            lag_topic = status_maxlag.get('topic')
            
            start_lag = start_info.get('lag')
            start_ts = str(datetime.fromtimestamp(int(start_info.get('timestamp')/1000))
            end_lag = end_info.get('lag')
            end_ts = str(datetime.fromtimestamp(int(end_info.get('timestamp')/1000))            
            
            return lag_topic, status, start_lag, start_ts, end_lag, end_ts
        else:
            return
        

burrow = Burrow()
burrow.get_consumer_status() 