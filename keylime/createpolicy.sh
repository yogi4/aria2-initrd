#Create Allow List
/usr/share/keylime/scripts/create_allowlist.sh -o allowlist.txt -h sha256sum

copy this to server/verifier 
# scp <allowlist.txt> root@<tenant.ip>:/root/<allowlist.txt>


On server
#Create Exclude List 
^/root/rpmbuild/.*$
^/etc/.*$
^/usr/.*$
#Create Policy with allowlist and exclude list 

keylime_create_policy -a allowlist.txt -e excludelist.txt -o policy.json

