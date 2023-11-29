#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

echo -e "\n~~ Number guessing Game ~~\n"

#Ask for username
echo Enter your username:
read USERNAME

#Generate random number
R_NUMBER=$(( RANDOM % 1000 + 1 ))

#Store number of tries
TRIES=0

#Game function
GAME() {
  #Add one to number of tries
  ((TRIES++))
  
  if [[ $1 ]]
  then
    echo -e $1
  else
    echo -e "\nGuess the secret number between 1 and 1000:"
  fi
  read GUESS

  #Check if number
  if [[ $GUESS =~ ^[0-9]+$ ]]
  then
    #Check if equal
    if [[ $GUESS == $R_NUMBER ]]
    then
      #Grab current user_id
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")
      #Insert game result
      GAME_INSERT=$($PSQL "INSERT INTO games(user_id, number_to_guess, number_of_tries, game_won) VALUES($USER_ID, $R_NUMBER, $TRIES, TRUE);")
      #If insert is succesful
      if [[ $GAME_INSERT == "INSERT 0 1" ]]
      then
        #Calculate and get number of games and best game from current user
        NUMBER_GAMES=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID;")
        BEST_GAME=$($PSQL "SELECT MIN(number_of_tries) FROM games WHERE user_id = $USER_ID;")
        #Update best game and number of games into current user
        BEST_INSERT=$($PSQL "UPDATE users SET games_played = $NUMBER_GAMES, best_game = $BEST_GAME WHERE user_id = $USER_ID;")
        echo -e "\nYou guessed it in $TRIES tries. The secret number was $R_NUMBER. Nice job!"
      fi
    #If not
    #Check if bigger
    elif [[ $GUESS > $R_NUMBER ]]
    then
      GAME "\nIt's lower than that, guess again:"
    #If not it must be smaller
    else
      GAME "\nIt's higher than that, guess again:"
    fi
  #If not
  else
    GAME "\nThat is not an integer, guess again:"
  fi
}

#Check for username on database
DB_USER=$($PSQL "SELECT * FROM users WHERE username = '$USERNAME'")

#If user is new
if [[ -z $DB_USER ]]
then
  #Enter a new username on the database, by default games played is zero and best game is zero
  USER_INSERT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0);")
  #If user insert is succesfull
  if [[ $USER_INSERT == "INSERT 0 1" ]]
  then
    #Welcome the new user
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
    #Start the game
    GAME
  fi
else
  #Welcome back the user with his/her past stats
  echo $DB_USER | while  IFS="|" read ID NAME GAMES BEST
  do
    NAME_FIX=$(echo $NAME | sed -E 's/^ *| *$//g')
    GAMES_FIX=$(echo $GAMES | sed -E 's/^ *| *$//g')
    BEST_FIX=$(echo $BEST | sed -E 's/^ *| *$//g')
    echo -e "\nWelcome back, $NAME_FIX! You have played $GAMES_FIX games, and your best game took $BEST_FIX guesses."
  done
  #Start the game
  GAME
fi
