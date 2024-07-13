#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guessing_game --tuples-only -c"

FORMAT_STRING() {
  # this removes leading spaces
    local str="$1"
    str="$(echo "$str" | sed -r 's/^ *| *$//g')"
    echo "$str"
}

# Generate a random number between 1 and 100
MIN=1
MAX=1000
SECRET_NUMBER=$(( RANDOM % ($MAX - $MIN + 1) + $MIN ))
EXIT_NUMBER=0
NUMBER_OF_GUESSES=0

# Read user name
while true; do
  echo -e "Enter your username:"
  read USER_NAME
  # if USER_NAME <=22 break
  if [ ${#USER_NAME} -gt 22 ]
  then
    echo "Your username is too long. It should be maximum 22 characters long."
  else
    # USER_NAME > 22
    break
  fi
done

# Check user name in database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USER_NAME';")

if [[ -z $USER_ID ]]
then
  # Name does not exist
  echo -e "Welcome, $USER_NAME! It looks like this is your first time here."
  # insert new user
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users (name, games_played) VALUES('$USER_NAME',0);")
else
# Name exists - Get information
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE name = '$USER_NAME';")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE name = '$USER_NAME';")

  # format strings
  GAMES_PLAYED_F=$(FORMAT_STRING "$GAMES_PLAYED")
  BEST_GAME_F=$(FORMAT_STRING "$BEST_GAME")

  echo -e "Welcome back, $USER_NAME! You have played $GAMES_PLAYED_F games, and your best game took $BEST_GAME_F guesses."
fi

# Validate user_input (must be between 1 and 1000) (Only numbers are accepted. No decimals.)
while true; do
  echo -e "\nGuess the secret number between $MIN and $MAX:"
  read USER_INPUT
  ((NUMBER_OF_GUESSES += 1))
  #echo $USER_INPUT
  if [[ ! $USER_INPUT =~ ^[0-9]+$ ]]
  then
    # Invalid input
    echo -e "That is not an integer, guess again:"
  elif [[ $USER_INPUT -gt 1000 ]] || [[ $USER_INPUT -lt 1 ]]
  then
    echo -e "The input $USER_INPUT is not between $MIN and $MAX:"
  else 
    break
  fi
done

while true; do
# check if input matches the random number

  if [[ $SECRET_NUMBER -eq $USER_INPUT ]]
  then
    echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif [[ $SECRET_NUMBER -gt $USER_INPUT ]]
  then
    echo -e "It's higher than that, guess again:"
  elif [[ $SECRET_NUMBER -lt $USER_INPUT ]]
  then
    echo -e "It's lower than that, guess again:"
  # "emergency exit" -> 0
  elif [[ $USER_INPUT -eq $EXIT_NUMBER ]]
  then
    exit
  fi
  # read new guess
  read USER_INPUT
  # increment number of guesses
  ((NUMBER_OF_GUESSES += 1))
done

# update database
  #increase number of games played
  ((GAMES_PLAYED_F += 1))
  UPDATE_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED_F WHERE name = '$USER_NAME';")

  # update best game, if it was the best game so far
  if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME_F ]] || [[ -z $BEST_GAME_F ]] 
  then
    UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE name = '$USER_NAME';")
  fi

