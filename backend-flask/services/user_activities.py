from datetime import datetime, timedelta, timezone
from lib.db import db

class UserActivities:
  def run(user_handle):
    model = {
      'errors': None,
      'data': None
    }

    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['blank_user_handle']
    else:
      ## removed the stubbed response, now a sql request
      sql = db.template('users','show')
      results = db.query_array_json(sql,{'handle': user_handle})
      model['data'] = results
    return model


    # (sql,{
    #    'cognito_user_id': cognito_user_id,
    #    'user_receiver_handle': rev_handle
    #  })