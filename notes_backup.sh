 #Bootloader Configuration
menuentry 'Aria2 Initrd with TPM Attestation' {
    set root=(hd0,1)
    linux /vmlinuz tpm_attestation=1
    initrd /initrd.img
}


#Additional Presetup commands

# Generate an attestation key during the build process
tpm2_createprimary -C o -g sha256 -G rsa -c /etc/tpm/primary.ctx
tpm2_create -C /etc/tpm/primary.ctx -g sha256 -G rsa -u /etc/tpm/attestation_key.pub -r /etc/tpm/attestation_key.priv
tpm2_load -C /etc/tpm/primary.ctx -u /etc/tpm/attestation_key.pub -r /etc/tpm/attestation_key.priv -c /etc/tpm/attestation_key.ctx



#Decompress initrd.img 
sudo mkdir initrd_contents
cd initrd_contents/
sudo gzip -dc ../custom-initrd.img | cpio -idmv


docker run --rm -v -it --privileged "$(pwd)/output:/workspace/output" yogi4/aria2-initrd:tpm /bin/sh

initrd=custom-initrd.img url=http://example.com/resource1,http://example.com/resource2
kexec -l /boot/vmlinuz-5.14.0-533.el9.x86_64 --initrd=initrd.img --append="url= http://ipv4.download.thinkbroadband.com/10MB.zip console=ttyS0 tpm_attestation=1 attestation_server=http://<SERVER_IP>:5000/verify"
docker pull yogi4/aria2-initrd:tpm
docker run --rm -it --privileged -v "$(pwd)/output:/workspace/output" yogi4/aria2-initrd:tpm /bin/sh


tpm_attestation=1 attestation_server=http://<SERVER_IP>:5000/verify


#Scripts to install and run docker on Centos
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run hello-world
#Run as Privileged User
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
sudo usermod -aG docker $USER
sudo su