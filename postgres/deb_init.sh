#!/bin/bash

docker compose up -d;

chmod -R 770 pgadmin_data;  # allow group write and disallow anything by others
echo 'chmod pgadmin_data success';

function check_postgres_is_ready() {  # checks if postgres is completely up
  if docker compose logs postgres | grep 'database system is ready to accept connections'; then
    echo "postgres is ready";
    return "1";
  else
    echo "postgres is not ready yet";
    return "0";
  fi
}

while check_postgres_is_ready  # time delay for postgres deployment
do
  echo 'wait for postgres';
  sleep 1;
done

chmod -R 770 pgdata; # allow rwx for group
echo 'chmod pgdata success'

docker compose logs -f;