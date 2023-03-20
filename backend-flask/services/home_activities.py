from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.db import db
import logging

# get root logger
home_logger = logging.getLogger('app') 

tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    home_logger.info('message from INSIDE home activities module')
    #with tracer.start_as_current_span("home-activites-mock-data"):
 
    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    span.set_attribute("app.result_length", len(results))
    return results
