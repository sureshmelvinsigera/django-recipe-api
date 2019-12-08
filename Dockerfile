# base image
FROM python:3.7-alpine AS compile-image

# install compile dependencies for psypcopg2 and Pillow
RUN apk add --update --no-cache gcc jpeg-dev libc-dev \
          linux-headers postgresql-dev musl-dev zlib zlib-dev

# virtualenv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# install required packages
RUN pip install --upgrade pip && pip install pip-tools
COPY ./requirements.in .
RUN pip-compile requirements.in > requirements.txt && pip-sync
RUN pip install -r requirements.txt

# runtime-image
FROM python:3.7-alpine AS runtime-image

# install dependencies for postgres
RUN apk add --update --no-cache postgresql-client jpeg-dev

# copy Python dependencies from build image
COPY --from=compile-image /opt/venv /opt/venv

# create working directory and non-root user
RUN mkdir /app
WORKDIR /app

RUN mkdir -p /vol/web/media && mkdir -p /vol/web/static
RUN adduser -D user
RUN chown -R user:user /vol/ && chmod -R 755 /vol/web

# switch to non-root user
USER user

# copy app
COPY ./app /app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PATH="/opt/venv/bin:$PATH"
