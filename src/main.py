import select
import socket
import gesture_recognition.config
import yaml
import json

# config = None
# config_exists = gesture_recognition.config.filename is not None
#
# if config_exists:
# 	with open(gesture_recognition.config.filename, 'r') as stream:
# 		config = yaml.load(stream)
#
# if config_exists:
# 	port = config.get('logging', 'INFO').upper()

# Create the client.
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect(('10.0.0.254', 12345))

msg = {}
msg_header = {'type': 'trigger'}
msg_body = {}

msg['message_header'] = msg_header
msg['message_body'] = msg_body

if __name__ == '__main__':
	client_socket.send(json.dumps(msg))
	print client_socket.recv(1024).decode('utf-8')
	client_socket.close()
