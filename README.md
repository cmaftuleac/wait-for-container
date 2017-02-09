# Script for waiting for a named container
Inspired by https://github.com/vishnubob/wait-for-it

# Prologue
In the docker-compose version 2.1 there is a possibility control the services start-up order.
However there is no possibility to wait until a service to become ready or the one-time job to exit.
For the cases when the service opens a port you can use that to check if the service start-up is completed by using this script: https://github.com/vishnubob/wait-for-it

However for a single run job there is no such possibility.
Imagine a service that runs a mysql schema update as one time job, and a web service that connects to mysql.
The web service expects that schema will be updated however it depends how fast the schema update will take place, in some cases it can be pretty logn operation, and web service initialization can occur before the schema gets fully updated.


# Usage
    wait-for-container.sh 
        -n                  Wait until the named container exit, and return its exit code
        -t                  Timeout, default is not to wait at all (just check and exit)
        -s|--strict         Only execute subcommand if the test succeeds
        -h|--help           Show this message
        -- COMMAND ARGS     Execute command with args after the test finishes

# Example
    $ wait-for-container.sh -n mysqldb_schema -t 120
Wait for the container mysqldb_schema to run and return its exit code

    $ wait-for-container.sh -n mysqldb_schema -s -- echo "Schema updated"
Wait for the container mysqldb_schema to run and run echo only if schema update returned 0 exit code


# Example of usage in the context of docker-compose with depends_on 

    version: '2.1'
    
    services:
      build: schema
      schema:
        depends_on:
          mysqldb:
            condition: service_healthy
      
      api:
        build: api
        command: ./wait-for-container.sh -n schema -s -- ./start_api.sh
        depends_on:
          mysqldb:
            condition: service_healthy
      
      mysqldb:
        build: mysqldb
        healthcheck:
          test: "nc -z localhost 3306"
          interval: 1s
          retries: 120

By using command relying on the script itself to do the wait.


    version: '2.1'
    
    services:
      build: schema
      schema:
        depends_on:
          mysqldb:
            condition: service_healthy
        healthcheck:
          test: "./wait-for-container.sh -n schema"
          interval: 1s
          retries: 120
      
      api:
        build: api
        command: ./start_api.sh
        depends_on:
          schema:
            condition: service_healthy
          mysqldb:
            condition: service_healthy
      
      mysqldb:
        build: mysqldb
        healthcheck:
          test: "nc -z localhost 3306"
          interval: 1s
          retries: 120

By using the script only for healthcheck.




