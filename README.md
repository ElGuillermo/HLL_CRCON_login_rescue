# HLL_CRCON_login_rescue
Stand alone tool to create a rescue access to an Hell Let Loose (HLL) CRCON (see : https://github.com/MarechJ/hll_rcon_tool) install.

What it does :  
- stop CRCON  
- `(optional)` create a "rescue" CRCON superuser  
- `(optional)` change the CRCON database password  
- restart CRCON

## Reset password / Create a new CRCON user

- You lost your CRCON user password ?  
- Nobody else can log into the admin panel to change it or create a new user ?

This script can create a "rescue" superuser from the CRCON host terminal.  
You will be able to login to the admin panel, then reset your usual user password or create a new user account.  

Credentials :  
- user : 'rescue'  
- password : 'helpmeplease'

### :warning: Security notice
- Please make sure to delete/disable the "rescue" user once you're done with your maintenance operations.

## CRCON Database password updater

- You changed your PostgreSQL database password while the database has already been used ?  
  Now your CRCON can't access it anymore, as the database container still expects the "old" password.

This script can change the database password to match the one you've set for `HLL_DB_PASSWORD=` in the `.env` file.

## Install

> [!NOTE]
> The shell commands given below assume your CRCON is installed in `/root/hll_rcon_tool`.  
> You may have installed your CRCON in a different folder.  
>   
> Some Ubuntu Linux distributions disable the `root` user and `/root` folder by default.  
> In these, your default user is `ubuntu`, using the `/home/ubuntu` folder.  
> You should then find your CRCON in `/home/ubuntu/hll_rcon_tool`.  
>   
> If so, you'll have to adapt the commands below accordingly.

- Log into your CRCON host machine using SSH and enter these commands (one line at at time) :
```shell
cd /root/hll_rcon_tool
wget https://raw.githubusercontent.com/ElGuillermo/HLL_CRCON_login_rescue/refs/heads/main/login_rescue.sh
```

## Config
- Edit `/root/hll_rcon_tool/login_rescue.sh` and set the parameters to fit your needs.

## Use
- Get into CRCON's folder and launch the script using these commands :
```shell
cd /root/hll_rcon_tool
sudo sh ./login_rescue.sh
```
