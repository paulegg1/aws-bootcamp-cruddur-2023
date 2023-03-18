from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.db import pool, query_wrap_array
import logging

# get root logger
home_logger = logging.getLogger('app') 

tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    home_logger.info('message from INSIDE home activities module')
    with tracer.start_as_current_span("home-activites-mock-data"):
      now = datetime.now(timezone.utc).astimezone()
      span = trace.get_current_span()
      span.set_attribute("user.id", "andrewbrown")
      span.set_attribute("app.now", now.isoformat())

      sql = query_wrap_array("""
      SELECT
        *
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
      """)
      print(sql)

      with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchone()
          home_logger.info("======= NOT JSON =====")
          home_logger.info(json)    
      return json[0] 

      span.set_attribute("app.result_length", len(results))
      return results