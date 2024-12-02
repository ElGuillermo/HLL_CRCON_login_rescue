#!/bin/bash
# ┌───────────────────────────────────────────────────────────────────────────┐
# │ Configuration                                                             │
# └───────────────────────────────────────────────────────────────────────────┘
#
# The complete path of the CRCON folder
# - If not set (ie : CRCON_folder_path=""), it will try to find and use
#   any "hll_rcon_tool" folder on disk.
# - If your CRCON folder name isn't 'hll_rcon_tool', you must set it here.
# - Some Ubuntu distros disable 'root' user,
#   you may have installed CRCON in "/home/ubuntu/hll_rcon_tool" then.
# default : "/root/hll_rcon_tool"
CRCON_folder_path="/root/hll_rcon_tool"

# Set to "yes" if you have modified any file that comes from CRCON repository
# First build will take ~3-4 minutes. Subsequent ones will take ~30 seconds.
# Default : "yes"
rebuild_before_restart="yes"

# Create a "rescue" CRCON superuser
# Its default password will be "helpmeplease"
# Don't forget to disable/delete this user after your maintenance operation
# Default : "no"
create_superuser="no"

# Change the CRCON database password
# It must match the HLL_DB_PASSWORD= value set in your .env file
# Default : "no"
change_db_pwd="no"
new_db_pwd=""  # Could be any non blank string without a space or a % sign
#
# └───────────────────────────────────────────────────────────────────────────┘

clear
printf "┌─────────────────────────────────────────────────────────────────────────────┐\n"
printf "│ Login rescue                                                                │\n"
printf "└─────────────────────────────────────────────────────────────────────────────┘\n\n"

# User must have root permissions
this_script_name=${0##*/}
if [ "$(id -u)" -ne 0 ]; then
  printf "\033[31mX\033[0m This \033[37m%s\033[0m script must be run with full permissions\n\n" "$this_script_name"
  printf "\033[32mWhat to do\033[0m : you must elevate your permissions using 'sudo' :\n"
  printf "\033[36msudo sh ./%s\033[0m\n\n" "$this_script_name"
  exit
else
  printf "\033[32mV\033[0m You have 'root' permissions.\n"
fi

# Check CRCON folder path
if [ -n "$CRCON_folder_path" ]; then
  crcon_dir=$CRCON_folder_path
  printf "\033[32mV\033[0m CRCON folder path has been set in config : \033[33m%s\033[0m\n" "$CRCON_folder_path"
else
  printf "\033[34m?\033[0m You didn't set any CRCON folder path in config\n"
  printf "  Trying to detect a \033[33mhll_rcon_tool\033[0m folder...\n"
  crcon_dir=$(find / -name "hll_rcon_tool" 2>/dev/null)
  if [ -n "$crcon_dir" ]; then
    printf "\033[32mV\033[0m CRCON folder detected in \033[33m%s\033[0m\n" "$crcon_dir"
  else
    printf "\033[31mX\033[0m No \033[33mhll_rcon_tool\033[0m folder could be found\n\n"
    printf "  - Maybe you renamed the \033[33mhll_rcon_tool\033[0m folder ?\n"
    printf "    (it will work the same, but you'll have to adapt every maintenance script)\n\n"
    printf "  If you followed the official install procedure,\n"
    printf "  your \033[33mhll_rcon_tool\033[0m folder should be found here :\n"
    printf "    - \033[33m/root/hll_rcon_tool\033[0m        (most Linux installs)\n"
    printf "    - \033[33m/home/ubuntu/hll_rcon_tool\033[0m (some Ubuntu installs)\n\n"
    printf "\033[32mWhat to do\033[0m :Find your CRCON folder, copy this script in it and relaunch it from there.\n\n"
    exit
  fi
fi

# Script has to be in the CRCON folder
this_script_dir=$(dirname -- "$( readlink -f -- "$0"; )";)
if [ ! "$this_script_dir" = "$crcon_dir" ]; then
  printf "\033[31mX\033[0m This script is not located in the CRCON folder\n"
  printf "  Script location : \033[33m%s\033[0m\n" "$this_script_dir"
  printf "  Should be here : \033[33m%s\033[0m\n" "$crcon_dir"
  printf "\033[32mFixing...\033[0m\n"
  cp "$this_script_dir/$this_script_name" "$crcon_dir"
  if [ -f "$crcon_dir/$this_script_name" ]; then
    printf "\033[32mV\033[0m \033[37m%s\033[0m has been copied in \033[33m%s\033[0m\n\n" "$this_script_name" "$crcon_dir"
    printf "\033[32mWhat to do\033[0m : enter the CRCON folder and relaunch the script using this command :\n"
    printf "\033[36mrm %s && cd %s && sudo sh ./%s\033[0m\n\n" "$this_script_dir/$this_script_name" "$crcon_dir" "$this_script_name"
    exit
  else
    printf "\033[31mX\033[0m \033[37m%s\033[0m couldn't be copied in \033[33m%s\033[0m\n\n" "$this_script_name" "$crcon_dir"
    printf "\033[32mWhat to do\033[0m : Find your CRCON folder, copy this script in it and relaunch it from there.\n\n"
    exit
  fi
else
  printf "\033[32mV\033[0m This script is located in the CRCON folder\n"
fi

# Script has to be launched from CRCON folder
current_dir=$(pwd | tr -d '\n')
if [ ! "$current_dir" = "$crcon_dir" ]; then
  printf "\033[31mX\033[0m This \033[37m%s\033[0m script should be run from the CRCON folder\n\n" "$this_script_name"
  printf "\033[32mWhat to do\033[0m : enter the CRCON folder and relaunch the script using this command :\n"
  printf "\033[36mcd %s && sudo sh ./%s\033[0m\n\n" "$crcon_dir" "$this_script_name"
  exit
else
  printf "\033[32mV\033[0m This script has been run from the CRCON folder\n"
fi

# CRCON config check
if [ ! -f "$crcon_dir/compose.yaml" ] || [ ! -f "$crcon_dir/.env" ]; then
  printf "\033[31mX\033[0m CRCON doesn't seem to be configured\n"
  if [ ! -f "$crcon_dir/compose.yaml" ]; then
    printf "  \033[31mX\033[0m There is no '\033[37mcompose.yaml\033[0m' file in \033[33m%s\033[0m\n" "$crcon_dir"
  fi
  if [ ! -f "$crcon_dir/.env" ]; then
    printf "  \033[31mX\033[0m There is no '\033[37m.env\033[0m' file in \033[33m%s\033[0m\n" "$crcon_dir"
  fi
  printf "\n\033[32mWhat to do\033[0m : check your CRCON install in \033[33m%s\033[0m\n\n" "$crcon_dir"
  exit
else
  printf "\033[32mV\033[0m CRCON seems to be configured\n"
fi

printf "\033[32mV Everything's fine\033[0m Let's renew these passwords !\n\n"

if [ $rebuild_before_restart = "yes" ]; then
  echo "┌──────────────────────────────────────┐"
  echo "│ Build CRCON                          │"
  echo "└──────────────────────────────────────┘"
  docker compose build
  echo "└──────────────────────────────────────┘"
  printf "Build CRCON : \033[32mdone\033[0m.\n\n"
fi

echo "┌──────────────────────────────────────┐"
echo "│ Stop CRCON                           │"
echo "└──────────────────────────────────────┘"
docker compose down
echo "└──────────────────────────────────────┘"
printf "Stop CRCON : \033[32mdone\033[0m.\n\n"

if [ $create_superuser = "yes" ]; then
  echo "┌──────────────────────────────────────┐"
  echo "│ Create a 'rescue' superuser          │"
  echo "└──────────────────────────────────────┘"
  printf "Starting postgres Docker container\n"
  docker compose up -d postgres
  printf "Create 'rescue' user\n"
  docker compose exec -it postgres psql -U rcon -c "INSERT INTO auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (1000, 'pbkdf2_sha256\$600000\$zFeqc7a2nnddTwRustKc9s\$gMZFtQb4b7EuZ3aeS4NceE0z0eqJCyPDTP1zl1mQBGw=', '2024-01-01 00:00:00+00', true, 'rescue', 'rescue', '', '', true, true, '2024-01-01 00:00:00+00');"
  printf "Stopping postgres Docker container\n"
  docker compose down
  echo "└──────────────────────────────────────┘"
  printf "Create a 'rescue' superuser : \033[32mdone\033[0m.\n\n"
fi

if [ $change_db_pwd = "yes" ]; then
  echo "┌──────────────────────────────────────┐"
  echo "│ Change database password             │"
  echo "└──────────────────────────────────────┘"
  if [ -n "$new_db_pwd" ]; then
    case "$new_db_pwd" in
      *\ * )
        printf "\033[31mX\033[0m The new password you've set in configuration contains an illegal character !\n"
        printf "  Make sure there's no space in it.\n"
        printf "\033[31mX\033[0m Database password wasn't updated.\n"
        db_pwd_updated="no"
        ;;
      *)
        case "$new_db_pwd" in
          *\%* )
            printf "\033[31mX\033[0m The new password you've set in configuration contains an illegal character !\n"
            printf "  Make sure there's no \033[31m%%\033[0m in it.\n"
            printf "\033[31mX\033[0m Database password wasn't updated.\n"
            db_pwd_updated="no"
            ;;
          *)
          printf "Starting postgres Docker container\n"
          docker compose up -d postgres
          printf "Setting new database password\n"
          docker compose exec -it postgres psql -U rcon -c "ALTER USER rcon WITH PASSWORD '$new_db_pwd';"
          printf "Stopping postgres Docker container\n"
          docker compose down
          db_pwd_updated="yes"
        esac
    esac
  else
    printf "\033[31mX\033[0m The new password you've set in configuration appears to be blank !\n"
    printf "\033[31mX\033[0m Database password wasn't updated.\n"
    db_pwd_updated="no"
  fi
  echo "└──────────────────────────────────────┘"
  printf "Change database password : \033[32mdone\033[0m.\n\n"
fi

echo "┌──────────────────────────────────────┐"
echo "│ Restart CRCON                        │"
echo "└──────────────────────────────────────┘"
docker compose up -d --remove-orphans
echo "└──────────────────────────────────────┘"
printf "Restart CRCON : \033[32mdone\033[0m.\n\n"

printf "┌──────────────────────────────────────┐\n"
printf "│ \033[32mLogin rescue complete\033[0m                │\n"
printf "└──────────────────────────────────────┘\n"
if [ "$create_superuser" = "yes" ]; then
  printf "A '\033[33mrescue\033[0m' CRCON user has been created.\n"
  printf "Its password is '\033[33mhelpmeplease\033[0m'\n\n"
  printf "\033[41;37m Security notice \033[0m\n"
  printf "Please make sure you delete/disable this '\033[33mrescue\033[0m' user\n"
  printf "once you're done with your maintenance operations.\n\n"
fi
if [ "$change_db_pwd" = "yes" ]; then
  if [ "$db_pwd_updated" = "yes" ]; then
    printf "The CRCON PostgreSQL database password has been updated.\n"
    printf "It's now set as '\033[33m%s\033[0m'\n" "$new_db_pwd"
    printf "It must match the HLL_DB_PASSWORD= value set in your .env file\n\n"
  else
    printf "\033[31mX\033[0m Database password wasn't updated.\n"
    printf "\033[31mX\033[0m The new password you've set in configuration may be blank,\n"
    printf "  or there is an illegal \033[31m%%\033[0m character or \033[31mspace\033[0m in it.\n"
    printf "\033[31mX\033[0m Database password wasn't updated.\n\n"
  fi
fi
printf "Wait for a full minute before using CRCON's interface.\n\n"
