# openvpn-mgmt
openvpn-mgmt is an easy user management script
## this script will:
* create vpn users by a base profile
* allow management of users ip's , groups  (openvpn ccd)
* send email to users 
* manage Google Authenthecator tokens easly
* email profiles otp link ot users


# Reqiured Packages
* openvpn-server
* easy-rsa
* libpam-google-authenticator
* mutt

# Instructions
* clone the script into desired directory
* edit base.conf file
* edit the variables within the script
* make sure openvpn ccd is configured.
* make sure you can send emails .


# USAGE
## creating new account 
1.  ./openvpn-mgmt.sh user.name
2.   approve the new account creation
3.   choose the user group (ip subnet route spicifed at the vpn conf)
4.   specify available IP addresses from the chosen group (client and gateway)
5.   approve the email to send the ovpn config and the barcode.

## additional options:
** when running the script for a user that already created you'll able to choose one of the options below:
* Delete User
* Resend Token
* Recreate Token
* Change User Group
* Resend email (token & ovpn config)
