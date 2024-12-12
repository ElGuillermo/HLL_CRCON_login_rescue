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
CRCON_folder_path=""

# Create a "rescue" CRCON superuser
# Its default password will be "helpmeplease"
# Don't forget to disable/delete this user after your maintenance operation !
# Default : "no"
create_superuser="no"

# Change the CRCON database password
# It must match the HLL_DB_PASSWORD= value set in your .env file
# Default : "no"
change_db_pwd="no"
new_db_pwd=""  # Could be any non-blank string without a space or a % sign
#
# └───────────────────────────────────────────────────────────────────────────┘

is_CRCON_configured() {
    printf "%s└ \033[34m?\033[0m Testing folder : \033[33m%s\033[0m\n" "$2" "$1"
    if [ -f "$1/compose.yaml" ] && [ -f "$1/.env" ]; then
        printf "%s  └ \033[32mV\033[0m A configured CRCON install has been found in \033[33m%s\033[0m\n" "$2" "$1"
    else
        missing_env=0
        missing_compose=0
        wrong_compose_name=0
        deprecated_compose=0
        if [ ! -f "$1/.env" ]; then
          missing_env=1
          printf "%s  └ \033[31mX\033[0m Missing file : '\033[37m.env\033[0m'\n" "$2"
        fi
        if [ ! -f "$1/compose.yaml" ]; then
            missing_compose=1
            printf "%s  └ \033[31mX\033[0m Missing file : '\033[37mcompose.yaml\033[0m'\n" "$2"
            if [ -f "$1/compose.yml" ]; then
                wrong_compose_name=1
                printf "%s    └ \033[31m!\033[0m Wrongly named file found : '\033[37mcompose.yml\033[0m'\n" "$2"
            fi
            if [ -f "$1/docker-compose.yml" ]; then
                deprecated_compose=1
                printf "%s    └ \033[31m!\033[0m Deprecated file found : '\033[37mdocker-compose.yml\033[0m'\n" "$2"
            fi
        fi
        printf "\n\033[32mWhat to do\033[0m :\n"
        if [ $missing_env = 1 ]; then
            printf "\n - Follow the install procedure to create a '\033[37m.env\033[0m' file\n"
        fi
        if [ $missing_compose = 1 ]; then
            printf "\n - Follow the install procedure to create a '\033[37mcompose.yaml\033[0m' file\n"
            if [ $wrong_compose_name = 1 ]; then
                printf "\n   If your CRCON starts normally using '\033[37mcompose.yml\033[0m'\n"
                printf "   you should rename this file using this command :\n"
                printf "   \033[36mmv %s/compose.yml %s/compose.yaml\033[0m\n" "$1" "$1"
            fi
            if [ $deprecated_compose = 1 ]; then
                printf "\n   '\033[37mdocker-compose.yml\033[0m' was used by the deprecated (jul. 2023) 'docker-compose' command\n"
                printf "   You should delete it and use a '\033[37mcompose.yaml\033[0m' file\n"
            fi
        fi
        printf "\n"
        exit
    fi
}

clear
printf "┌─────────────────────────────────────────────────────────────────────────────┐\n"
printf "│ Checking prerequisites                                                      │\n"
printf "└─────────────────────────────────────────────────────────────────────────────┘\n\n"

this_script_dir=$(dirname -- "$( readlink -f -- "$0"; )";)
this_script_name=${0##*/}

# User must have root permissions
if [ "$(id -u)" -ne 0 ]; then
    printf "\033[31mX\033[0m This \033[37m%s\033[0m script must be run with full permissions\n\n" "$this_script_name"
    printf "\033[32mWhat to do\033[0m : you must elevate your permissions using 'sudo' :\n"
    printf "\033[36msudo sh ./%s\033[0m\n\n" "$this_script_name"
    exit
else
    printf "\033[32mV\033[0m You have 'root' permissions\n"
fi

# Check CRCON folder path
if [ -n "$CRCON_folder_path" ]; then
    printf "\033[32mV\033[0m CRCON folder path has been set in config : \033[33m%s\033[0m\n" "$CRCON_folder_path"
    is_CRCON_configured "$CRCON_folder_path" ""
    crcon_dir="$CRCON_folder_path"
else
    printf "\033[31mX\033[0m You didn't set any CRCON folder path in config\n"
    printf "└ \033[34m?\033[0m Trying to detect a \033[33mhll_rcon_tool\033[0m folder\n"
    detected_dir=$(find / -name "hll_rcon_tool" 2>/dev/null)
    if [ -n "$detected_dir" ]; then
        is_CRCON_configured "$detected_dir" "  "
        crcon_dir="$detected_dir"
    else
        printf "  └ \033[31mX\033[0m No \033[33mhll_rcon_tool\033[0m folder could be found\n"
        printf "    └ \033[34m?\033[0m Trying to detect a CRCON install in current folder\n"
        is_CRCON_configured "$this_script_dir" "      "
        crcon_dir="$this_script_dir"
    fi
fi

# This script has to be in the CRCON folder
if [ ! "$this_script_dir" = "$crcon_dir" ]; then
    printf "\033[31mX\033[0m This script is not located in the CRCON folder\n"
    printf "  Script location : \033[33m%s\033[0m\n" "$this_script_dir"
    printf "  Should be here : \033[33m%s\033[0m\n" "$crcon_dir"
    printf "  \033[32mTrying to fix...\033[0m\n"
    cp "$this_script_dir/$this_script_name" "$crcon_dir"
    if [ -f "$crcon_dir/$this_script_name" ]; then
        printf "  \033[32mV\033[0m \033[37m%s\033[0m has been copied in \033[33m%s\033[0m\n\n" "$this_script_name" "$crcon_dir"
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
    printf "\033[31mX\033[0m This script should be run from the CRCON folder\n\n"
    printf "\033[32mWhat to do\033[0m : enter the CRCON folder and relaunch the script using this command :\n"
    printf "\033[36mcd %s && sudo sh ./%s\033[0m\n\n" "$crcon_dir" "$this_script_name"
    exit
else
    printf "\033[32mV\033[0m This script has been run from the CRCON folder\n"
fi

printf "\033[32mV Everything's fine\033[0m\n\n"

printf "┌─────────────────────────────────────────────────────────────────────────────┐\n"
printf "│ Login rescue                                                                │\n"
printf "└─────────────────────────────────────────────────────────────────────────────┘\n\n"

printf "┌──────────────────────────────────────┐\n"
printf "│ Stop CRCON                           │\n"
printf "└──────────────────────────────────────┘\n"
if {
    [ "$(docker container inspect -f '{{.State.Running}}' hll_rcon_tool-frontend_1-1)" = "true" ] \
    || [ "$(docker container inspect -f '{{.State.Running}}' hll_rcon_tool-supervisor_1-1)" = "true" ] \
    || [ "$(docker container inspect -f '{{.State.Running}}' hll_rcon_tool-backend_1-1)" = "true" ] \
    || [ "$(docker container inspect -f '{{.State.Running}}' hll_rcon_tool-maintenance-1)" = "true" ] \
    || [ "$(docker container inspect -f '{{.State.Running}}' hll_rcon_tool-postgres-1)" = "true" ] \
    || [ "$(docker container inspect -f '{{.State.Running}}' hll_rcon_tool-redis-1)" = "true" ]
}; then
    docker compose down
    if [ $? -eq 0 ]; then
        CRCON_stopped="yes"
        printf "└──────────────────────────────────────┘\n"
        printf "Stop CRCON : \033[32msuccess\033[0m\n\n"
    else
        CRCON_stopped="no"
        printf "└──────────────────────────────────────┘\n"
        printf "Stop CRCON : \033[31mfailure\033[0m\n\n"
    fi
else
    CRCON_stopped="yes"
    printf "└──────────────────────────────────────┘\n"
    printf "Stop CRCON : \033[32mIt was already stopped\033[0m\n\n"
fi

if [ $create_superuser = "yes" ]; then
    printf "┌──────────────────────────────────────┐\n"
    printf "│ Create a 'rescue' superuser          │\n"
    printf "└──────────────────────────────────────┘\n"
    if [ "$CRCON_stopped" = "yes" ]; then
        docker compose up -d postgres
        if [ $? -eq 0 ]; then
            printf "\033[32mV\033[0m Postgres Docker container has been started\n"
            docker compose exec -it postgres psql -U rcon -c "INSERT INTO auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (1000, 'pbkdf2_sha256\$600000\$zFeqc7a2nnddTwRustKc9s\$gMZFtQb4b7EuZ3aeS4NceE0z0eqJCyPDTP1zl1mQBGw=', '2024-01-01 00:00:00+00', true, 'rescue', 'rescue', '', '', true, true, '2024-01-01 00:00:00+00');"
            if [ $? -eq 0 ]; then
                rescue_user_created="yes"
                printf "\033[32mV\033[0m 'rescue' user has been created\n"
                docker compose down
                if [ $? -eq 0 ]; then
                    printf "\033[32mV\033[0m Postgres Docker container has been stopped\n"
                else
                    printf "\033[31mX\033[0m Postgres Docker container couldn't be stopped\n"
                fi
            else
                rescue_user_created="no"
                printf "\033[31mX\033[0m 'rescue' user couldn't be created\n"
            fi
        else
            rescue_user_created="no"
            printf "\033[31mX\033[0m Postgres Docker container couldn't be started\n"
        fi
    else
        rescue_user_created="no"
        printf "\033[31mX\033[0m CRCON couldn't be stopped\n"
    fi
    printf "└──────────────────────────────────────┘\n"
    if [ "$rescue_user_created" = "yes" ]; then
        printf "Create a 'rescue' superuser : \033[32msuccess\033[0m\n\n"
    else
        printf "Create a 'rescue' superuser : \033[31mfailure\033[0m\n\n"
    fi
fi

if [ $change_db_pwd = "yes" ]; then
    echo "┌──────────────────────────────────────┐"
    echo "│ Change database password             │"
    echo "└──────────────────────────────────────┘"
    if [ -n "$new_db_pwd" ]; then
        if echo "$new_db_pwd" | grep -q "%"; then
            db_pwd_updatable="no"
            printf "\033[31mX\033[0m The new password you've set in configuration contains an illegal character\n"
            printf "  Make sure there's no \033[31m%%\033[0m in it.\n"
        fi
        if echo "$new_db_pwd" | grep -q " "; then
            db_pwd_updatable="no"
            printf "\033[31mX\033[0m The new password you've set in configuration contains an illegal character\n"
            printf "  Make sure there's no \033[31mspace\033[0m in it.\n"
        fi
    else
        db_pwd_updatable="no"
        printf "\033[31mX\033[0m The new password you've set in configuration appears to be blank\n"
    fi
    if [ "$db_pwd_updatable" = "no" ]; then
        printf "\033[31mX\033[0m Database password can't be updated\n"
    else
        docker compose up -d postgres
        if [ $? -eq 0 ]; then
            db_pwd_updated="yes"
            printf "\033[32mV\033[0m Postgres Docker container successfully started/n"
        else
            db_pwd_updated="no"
            printf "\033[31mX\033[0m Postgres Docker container couldn't be started/n"
        fi
        docker compose exec -it postgres psql -U rcon -c "ALTER USER rcon WITH PASSWORD '$new_db_pwd';"
        if [ $? -eq 0 ]; then
            db_pwd_updated="yes"
            printf "\033[32mV\033[0m Database password successfully updated/n"
        else
            db_pwd_updated="no"
            printf "\033[31mX\033[0m Database password couldn't be updated/n"
        fi
        docker compose down
        if [ $? -eq 0 ]; then
            db_pwd_updated="yes"
            printf "\033[32mV\033[0m Postgres Docker container successfully stopped/n"
        else
            db_pwd_updated="yes"
            printf "\033[31mX\033[0m Postgres Docker container couldn't be stopped/n"
        fi
    fi
    printf "└──────────────────────────────────────┘\n"
    if [ "$db_pwd_updated" = "yes" ]; then
        printf "Change database password : \033[32msuccess\033[0m\n\n"
    else
        printf "Change database password : \033[31mfailure\033[0m\n\n"
    fi
fi

printf "┌──────────────────────────────────────┐\n"
printf "│ Restart CRCON                        │\n"
printf "└──────────────────────────────────────┘\n"
docker compose up -d --remove-orphans
if [ $? -eq 0 ]; then
    CRCON_restarted="yes"
    printf "└──────────────────────────────────────┘\n"
    printf "Restart CRCON : \033[32msuccess\033[0m\n\n"
else
    CRCON_restarted="no"
    printf "└──────────────────────────────────────┘\n"
    printf "Restart CRCON : \033[31mfailure\033[0m\n\n"
fi

printf "┌──────────────────────────────────────┐\n"
printf "│ Login rescue complete                │\n"
printf "└──────────────────────────────────────┘\n"
if [ "$CRCON_stopped" = "no" ]; then
    printf "\033[31mX\033[0m CRCON couldn't be stopped\n\n"
else
    printf "\033[32mV\033[0m CRCON successfully stopped\n\n"
fi
if [ "$create_superuser" = "yes" ]; then
    if [ "$rescue_user_created" = "yes" ]; then
        printf "\033[32mV\033[0m '\033[33mrescue\033[0m' CRCON user has been created.\n"
        printf "  Its password is '\033[33mhelpmeplease\033[0m'\n\n"
        printf "  \033[41;37m Security notice \033[0m\n"
        printf "  Please make sure you delete/disable this '\033[33mrescue\033[0m' user\n"
        printf "  once you're done with your maintenance operations.\n\n"
    else
        printf "\033[31mX\033[0m '\033[33mrescue\033[0m' CRCON user couldn't be created\n\n"
    fi
    if [ "$change_db_pwd" = "yes" ]; then
        if [ "$db_pwd_updated" = "yes" ]; then
            printf "\033[32mV\033[0m CRCON PostgreSQL database password has been updated\n"
            printf "  It's now set as '\033[33m%s\033[0m'\n" "$new_db_pwd"
            printf "  It must match the \033[33mHLL_DB_PASSWORD=\033[0m value set in your .env file\n\n"
        else
        printf "\033[31mX\033[0m CRCON PostgreSQL database password wasn't updated\n\n"
    fi
fi
