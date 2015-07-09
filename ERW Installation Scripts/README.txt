1) Deploy new vapp containing 6 'base_CentOS' images

2) Name VMs:
    a) bind
    b) ldap
    c) db
    d) alfresco
    e) nfs
    f) proxy
	
3) Edit properties of 'db' & 'alfresco' VMs - change properties:
    a) CPU - from: 1, to: 2
    b) Memory - from: 2, to: 16
    c) HDD - add second drive: 500

3.1)  Edit properties of 'nfs' - change properties:
    a) HDD - add second drive: 1024


3.2) Add 1 'ubuntu-server-14.04-lvm' VM to the vApp named 'sync'

3.3) Edit properties of 'sync' - change properties:
    a) CPU - from: 1, to: 2
    b) Memory - from: 2, to: 8
    c) HDD - add second drive: 500


4) Power on all VMs and allow to run through guest customisations - Ubuntu server take longer than CentOS. 

5) Log into 'bind' VM as root and download (source?): 
    a) installer scripts 
    b) private rsa key for 'erw' user

6) Name and place private key in /root/.ssh/private_key.rsa

7) Adjust private key permissions mask (chmod 600)

8) Adjust erw_install.cfg

8.5) Execute erw_install.sh

9) Accept SSH fingerprint for the 6 servers (answer 'yes' when prompted). 
   If you are not prompted 6 times you will likely have missed an IP address in the config file and will need to start again.
   
10) The bind (DNS) installation will run first. Success is indicated by the 'named' service starting successfully.
    Press enter to continue when prompted.

11) Next is the FreeIPA (ldap) installation. This takes some time and doesn't provide a lot of output on screen, be patient.
    Success is indicated by the summary on screen. Press enter to continue when prompted.
	
12) Next is the Postgre (db) installation. Success is indicated by the posgresql service starting successfully.
    Press enter to continue when prompted.
	
13) Next is the alfresco installation. This takes some time and success is indicated by the tomcat service starting successfully.
    Press enter to continue when prompted.

13.1) Next is the NFS installation. Formatting the 2nd drive takes some time, be patient. Success is indicated by the starting of the NFS server
    Press enter to continue when prompted.

13.2) Next is the CMIS Sync installation.  Formatting the 2nd drive can take some time, be patient.
      Press enter to complete the installation.
      	
14) All generated passwords will be present in the file 'install_<date>.log'.


