#!/usr/bin/env bash

#NOTE : Before execute this script please update joust_static.properties file.  Like... database connection, server details etc.

#SCHEME_DOMAIN_PORT="http://localhost:14443"

file="./joust_static.properties"
blanko="";

if [ -f "$file" ]
then
  echo "$file found."
  
  
 echo "Checking JQ installed Or not" 
  jq --version
  if [[ $? == 0 ]] ; then
  	echo "JQ already installed"
  else
  	echo "Start installing JQ"
  		sudo apt-get install jq
  	echo "JQ installed sucessfully!"
  fi
    
    
  echo "Reading $file file for get parameters."  
  while IFS='=' read -r key value
  do
    key=$(echo $key | tr '.' '_')
    if [[ ${value} != $blanko ]]; then 
    	eval ${key}=\${value}
    fi
  done < "$file"

  
  TRANSFER_PROTOCOL=${joust_request_transfer_protocol};
  SERVER_USER_HOST=${joust_user_server_host};
  SERVER_USER_PORT=${joust_user_server_port};
  CREATE_USER_REQUEST_ROUTE=${joust_create_user_request_route};
  CREATE_USER_REQUEST_CONTENT_TYPE=${joust_create_user_request_content_type};
  CREATE_USER_REQUEST_DATA_FILE_NAME=${joust_create_user_request_data_file_name};
  
  DATABASE_HOST=${joust_database_host};
  DATABASE_NAME=${joust_database_name};
  DATABASE_PORT=${joust_database_port};
  DATABASE_USERNAME=${joust_database_username};
  DATABASE_PASSWORD=${joust_database_password};
  
  #echo "Requesting Server details as below, which is mention in $file file"
  #echo "TRANSFER_PROTOCOL = $TRANSFER_PROTOCOL"
  #echo "SERVER_USER_HOST = $SERVER_USER_HOST"
  #echo "SERVER_USER_PORT = $SERVER_USER_PORT"
  #echo "CREATE_USER_REQUEST_ROUTE = $CREATE_USER_REQUEST_ROUTE"
  #echo "CREATE_USER_REQUEST_CONTENT_TYPE = $CREATE_USER_REQUEST_CONTENT_TYPE"
  #echo "CREATE_USER_REQUEST_DATA_FILE_NAME = $CREATE_USER_REQUEST_DATA_FILE_NAME"
  
  #echo "Database Connection Details as below which is mention in $file file"
  #echo "DATABASE_HOST = $DATABASE_HOST"
  #echo "DATABASE_NAME = $DATABASE_NAME"
  #echo "DATABASE_PORT = $DATABASE_PORT"
  #echo "DATABASE_USERNAME = $DATABASE_USERNAME"
  #echo "DATABASE_PASSWORD = $DATABASE_PASSWORD"
  

  echo "Sending curl requesting for create user"
  echo "URL = $TRANSFER_PROTOCOL://$SERVER_USER_HOST:$SERVER_USER_PORT/$CREATE_USER_REQUEST_ROUTE"
  
  curl -X POST -H "Content-Type: $CREATE_USER_REQUEST_CONTENT_TYPE" --insecure "$TRANSFER_PROTOCOL://$SERVER_USER_HOST:$SERVER_USER_PORT/$CREATE_USER_REQUEST_ROUTE" -d @$CREATE_USER_REQUEST_DATA_FILE_NAME
    	
  echo "New user created!"
 
 
  echo "Start Email Confirmation & Update User's Authority User to Admin";
  
  firstName=($(jq -r '.firstName' user_data.json))
  lastName=($(jq -r '.lastName' user_data.json))
  emailAddress=($(jq -r '.emailAddress' user_data.json))
  
  #echo "Created new user's details as below which is mention in user_data.json"
  #echo "firstName = $firstName"
  #echo "lastName = $lastName"
  #echo "emailAddress = $emailAddress"
	  
  sudo mysql -h $DATABASE_HOST -u $DATABASE_USERNAME -p$DATABASE_PASSWORD $DATABASE_NAME --execute="
	UPDATE users u
	INNER JOIN users_authorities au ON u.id = au.user_id
	INNER JOIN email_addresses ea ON u.email_address_id = ea.id
	SET u.unconfirmed_email_address_id = NULL,
	    u.email_address_confirmed = 1,
	    u.confirmed_email_address_id = u.email_address_id
	WHERE
	    lower(u.first_name) = lower('$firstName')
	    AND lower(u.last_name) = lower('$lastName')
	    AND lower(ea.email_address) = lower('$emailAddress');
	    

	UPDATE users_authorities au
	INNER JOIN users u ON au.user_id =  u.id
	    INNER JOIN email_addresses ea ON u.email_address_id = ea.id
	    INNER JOIN authorities a ON au.authority_id = a.id
	SET au.authority_id = 1
	WHERE
	    lower(u.first_name) = lower('$firstName')
	    AND lower(u.last_name) = lower('$lastName')
	    AND lower(ea.email_address) = lower('$emailAddress');"
 
 echo "Email Confirmed & Update User's Authority Sucessfully!";
 
else
  echo "$file not found."
fi
	
echo "New Admin user created sucessfully.!"
