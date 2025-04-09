# Cloudflare DDNS Updater
This script will keep the IPv4 and IPv6 addresses of Cloudflare DNS entries up to date with the current public IP address of the computer it is run on.

It uses the Cloudflare api and `jq` command for checking the IP address currently set for the DNS records and compares them with results from the [ipify.org](https://www.ipify.org/) api (https://api.ipify.org and https://api6.ipify.org)

If the IP addresses don't match, it will send a request to the Cloudflare api to set the new addresses.

## Setting up
First clone the repository and cd into it.

For configuration, rename the `.env-example` file to just `.env`. Then you can start filling it with values.
### ZONE_ID
You can get the zone id from the [Cloudflare Dashboard](https://dash.cloudflare.com) by clicking on the domain you want. It should be on the right side of the screen.
### API_TOKEN
To get the api token, go to your [Cloudflare Dashboard](https://dash.cloudflare.com) and scroll down to `Manage Account` on the left. Click on it and select `Account API Tokens`.  
Click on `Create Token` and select the `Edit zone DNS` template. Select the correct zone and create the token.
### DOMAIN
Set this to the (sub)domain you want to be updated. (For example `server.example.com`)
### RECORD_IDs
Go to your [Cloudflare Dashboard](https://dash.cloudflare.com), select your domain and go to `DNS`.

Here you need to create 2 DNS records for the same (sub)domain, one for IPv4 (Type A) and one for IPv6 (Type AAAA).  
Create them with the correct name, other settings will be filled by the script. For the address you can temporarily use `1.2.3.4` for IPv4 and `1:2:3:4:5:6:7:8` for IPv6.

TODO: Make it list only the wanted records based on DOMAIN defined above
Now that the records are created, you need to get their ids.  
To do this, you can run the script like this: `LIST_RECORDS=true ./run.sh`, which will list all your DNS records instead of updating anything.  
From there, find the records you want and copy their `"id"` fields into the `.env` file.
### TTL
The time-to-live of the records, in seconds. The default of 300 seconds (5 min) should be fine, but you can increase or decrease this if you plan on running the script at a different interval.

## Running the script
You can set up cron to run the script. Just run the `crontab -e` command and paste in the following (and use the actual path):
```cronexp
*/5 * * * * /path/to/run.sh
```
This will run the script every five minutes. 
