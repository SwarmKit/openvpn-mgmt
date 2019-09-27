# openvpn-mgmt
OpenVpn/Google Authenticator  easy user management shell script.

# Reqiured Packages
* openvpn
* easy-rsa
* libpam-google-authenticator
* mutt

# Instructions
* clone the script into desired directory
* edit the variables within the script
* openvpn ccd configuration

## creating new account 
1.  ./openvpn-mgmt.sh user.name
2.   approve the new account creation
3.   choose the user group (ip subnet route spicifed at the vpn conf)
4.   write available IP addressess (client and then gateway)
5.    choose email ot send the ovpn config and google auth scanner .

## addintinal options:
** if running the script for a user that alrady created youll able to choose one of the options below:
* Delete User
* Resend Token
* Recreate Token
* Change User Group
* Resend email (token and ovpn config)
