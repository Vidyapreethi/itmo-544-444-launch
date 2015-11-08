#!/bin/bash

aws rds create-db-instance-read-replica --db-instance-identifier pvpdbreplica --source-db-instance-identifier pvp-db
