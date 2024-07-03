#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
PSQL_M="psql -X --username=freecodecamp --dbname=postgres --tuples-only -c"
echo -e "\n~~~~~ MY SALON ~~~~~\n"

# MAIN MENU
MAIN_MENU() {

  # Print message if provided
  if [[ $1 ]]
  then
    echo -e "\n$1"
  else
    echo -e "Welcome to My Salon, how can I help you?\n"
  fi

  # display options
  ALL_SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id")
  echo "$ALL_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
  
  # read choice into SERVICE_ID_SELECTED
  read SERVICE_ID_SELECTED

  # Check if SERVICE_ID_SELECTED is a valid service
  case $SERVICE_ID_SELECTED in
    1) ;&
    2) ;&
    3) ;&
    4) ;&
    5) SERVICE_MANAGER $SERVICE_ID_SELECTED ;;
    *) MAIN_MENU "I could not find that service. What would you like today?"
  esac
}

SERVICE_MANAGER() {
  # Find service name
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$1")

  # ask for phone number
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE
  # get customer_name
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
  # if customer_name is found
  if [[ -z $CUSTOMER_NAME ]]
  then
    # ask for name
    echo -e "\nI don't have a record for that phone number, what's your name?"
    # create customer contact
    read CUSTOMER_NAME
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone,name) VALUES('$CUSTOMER_PHONE','$CUSTOMER_NAME')")
  fi
  # ask for appointment time
  echo -e "\nWhat time would you like your $(echo $SERVICE_NAME | sed -E 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')?"
  read SERVICE_TIME
  # find customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  # add new appointment
  INSERT_APPT_RESULT=$($PSQL "INSERT INTO appointments(customer_id,service_id,time) VALUES($CUSTOMER_ID,$SERVICE_ID_SELECTED,'$SERVICE_TIME')")
  # display message
  echo -e "\nI have put you down for a $(echo $SERVICE_NAME | sed -E 's/^ *| *$//g') at $(echo $SERVICE_TIME | sed -E 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')."
}

RESTORE_MANAGER() {
  echo -e "\nRestore Manager started..."

  # You should create a database named salon
  S0=$($PSQL_M "CREATE DATABASE salon")
  echo ">> $S0"

  # You should connect to your database, then create tables named customers, appointments, and services
  # Each table should have a primary key column that automatically increments
  # Each primary key column should follow the naming convention, table_name_id. For example, the customers table should have a customer_id key. 
  # Note that there’s no s at the end of customer
  # Your customers table should have phone that is a VARCHAR and must be unique
  # Your customers and services tables should have a name column
  # Your appointments table should have a time column that is a VARCHAR
  S1=$($PSQL  "CREATE TABLE customers(customer_id SERIAL PRIMARY KEY,
                                      phone VARCHAR(15) UNIQUE,
                                      name VARCHAR(80));
               CREATE TABLE services(service_id SERIAL PRIMARY KEY,
                                      name VARCHAR(80));
               CREATE TABLE appointments(appointment_id SERIAL PRIMARY KEY,
                                        customer_id INT,
                                        service_id INT,
                                        time VARCHAR(30))
              ")
  echo ">> $S1"

  # Your appointments table should have a customer_id foreign key that references the customer_id column from the customers table
  # Your appointments table should have a service_id foreign key that references the service_id column from the services table
  S2=$($PSQL  "ALTER TABLE appointments ADD FOREIGN KEY(customer_id) REFERENCES customers(customer_id);
               ALTER TABLE appointments ADD FOREIGN KEY(service_id) REFERENCES services(service_id)")
  echo ">> $S2"

  # You should have at least three rows in your services table for the different services you offer, one with a service_id of 1
  S3=$($PSQL  "INSERT INTO services(name) VALUES('cut'),('color'),('perm'),('style'),('trim')")
  echo ">> $S3"
}

RESET() {
  echo -e "\nReset started..."
  SALON_TABLES=$($PSQL "\d")

  # Drop all existing tables and sequences
  echo "$SALON_TABLES" | while read SCHEMA BAR NAME BAR TYPE BAR OWNER
  do
    if [[ $TYPE = "table" ]]
    then
      DROP_RESULT=$($PSQL "DROP TABLE $NAME")
      echo ">> $DROP_RESULT"
    elif [[ $TYPE = "sequence" ]]
    then
      DROP_RESULT=$($PSQL "DROP SEQUENCE $NAME")
      echo ">> $DROP_RESULT"
    fi
  done

  # Drop database
  DROP_SALON_RESULT=$($PSQL "DROP DATABASE salon")

  # Rebuild salon database from template
  RESTORE_MANAGER
}

# Execute RESTORE_MANAGER to rebuild from database template
# Execute RESET to delete all tables in salon >> Rebuild database using RESTORE_MANAGER
if [[ $1 = 'RESTORE' ]]
then
  RESTORE_MANAGER
elif [[ $1 == 'RESET' ]]
then
  RESET
fi

# Start main program
MAIN_MENU