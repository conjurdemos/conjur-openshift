$script = <<"SCRIPT"
if ! $(grep -q conjur-master /etc/hosts) 
then
  echo "127.0.0.1 conjur-master" >> /etc/hosts
fi
yum install -y kernel-devel-`uname -r` gcc make perl unzip vim
rpm -q conjur || rpm -i https://github.com/cyberark/conjur-cli/releases/download/v5.2.5/conjur-5.2.5-1.el6.x86_64.rpm
rm -rf /home/vagrant/openkube
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "openshift/origin-all-in-one"
  config.vm.box_version = "1.3.0"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8192"
  end

  config.vm.provision "shell", inline: $script
  config.vm.provision "file", source: File.join(File.dirname(__FILE__), '.'), destination: "/home/vagrant/scripts"
end
