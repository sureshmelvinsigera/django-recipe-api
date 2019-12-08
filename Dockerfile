# base image
FROM python:3.7-alpine

# virtualenv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# install dependencies
COPY ./requirements.in /requirements.in
RUN apk add --update --no-cache postgresql-client jpeg-dev
RUN apk add --update --no-cache --virtual .tmp-build-deps \
      gcc libc-dev linux-headers postgresql-dev musl-dev zlib zlib-dev
RUN pip install --upgrade pip && pip install pip-tools
RUN pip-compile requirements.in > requirements.txt && pip-sync
RUN pip install -r requirements.txt
RUN apk del .tmp-build-deps

# create working directory and non-root user
RUN mkdir /app
WORKDIR /app

RUN mkdir -p /vol/web/media
RUN mkdir -p /vol/web/static
RUN adduser -D user
RUN chown -R user:user /vol/
RUN chmod -R 755 /vol/web

USER user

# copy app
COPY ./app /app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
