FROM 540771840545.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

#ENV FLASK_ENV=development
# ENV FLASK_DEBUG=1
# ENV FRONTEND_URL="*"
# ENV BACKEND_URL="*"

EXPOSE ${PORT}
ENV PYTHONUNBUFFERED=1

# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]
#COPY runflask.sh runflask.sh
#CMD sh runflask.sh