import os

def lambda_handler(event, context):
   
   # print("Hello! this lambda function was created by chizzy on terraform")

    return {
    'body': 'Hello there buddy  {0}'.format(event['requestContext']['identity']['sourceIp']),
    'headers': {
      'Content-Type': 'text/plain'
    },
    'statusCode': 200
  }
