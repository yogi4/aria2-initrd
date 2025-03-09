 sudo dnf install -y epel-release
 sudo dnf install -y tpm2-abrmd tpm2-tools tpm2-tss
 sudo systemctl enable --now tpm2-abrmd.service
 systemctl status tpm2-abrmd.service



##install keylime agent
dnf install keylime-agent
vi /etc/keylime/agent.conf
Modify agent ip address 
Modify registrar ip address
Modify Revocation notifier Ip address

uuidgen 
Modify agent uuid 

# Add firewall rules
firewall-cmd --add-port 9001/tcp
firewall-cmd --add-port 9002/tcp
firewall-cmd --runtime-to-permanent

#Import keys 
mkdir /var/lib/keylime/cv_ca
scp root@192.168.1.16:/var/lib/keylime/cv_ca/cacert.crt /var/lib/keylime/cv_ca

systemctl enable --now keylime_agent

Optional 

rebuild kernel 
sudo dnf download --source raspberrypi2-kernel4
 sudo dnf builddep raspberrypi2-6.6.51-20241008.v8.1.el9.src.rpm


Note 
Change the CA file in /etc/keylime/ca.conf 

to use a password for keystore 

keylime_tenant -v 127.0.0.1 -c add -t 192.168.1.22 -u b36f42c4-ac6a-4d9d-8b59-68d9f91d1c12 --runtime-policy policy2.json --cert default
keylime_tenant -v 192.168.1.16 -c add -t 192.168.1.22 -u b36f42c4-ac6a-4d9d-8b59-68d9f91d1c12 --runtime-policy policy2.json --cert default
keylime_tenant -v 192.168.1.16 -c add -t 192.168.1.15 -u 40a10e69-7eba-4a27-ab86-aaddde733c3a --runtime-policy policy2.json --cert default
keylime_tenant -v 192.168.1.16 -c reglist

40a10e69-7eba-4a27-ab86-aaddde733c3a