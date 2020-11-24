$script = <<SCRIPT
  echo "=== Updating packages"

  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y aptitude
  sudo DEBIAN_FRONTEND=noninteractive aptitude update
  sudo DEBIAN_FRONTEND=noninteractive aptitude -y safe-upgrade

  echo "=== Installing new packages"

  sudo DEBIAN_FRONTEND=noninteractive aptitude install -y build-essentials libcurl4-gnutls-dev curl vim cmake

  echo "=== Installing latest git"

  sudo DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:git-core/ppa
  sudo DEBIAN_FRONTEND=noninteractive aptitude update
  sudo DEBIAN_FRONTEND=noninteractive aptitude install -y git

  echo "=== Installing janet"

  sudo git clone https://github.com/janet-lang/janet.git /tmp/janet
  cd /tmp/janet
  sudo make all test install
  sudo chmod 777 /usr/local/lib/janet

  echo "=== Installing joy"

  sudo jpm install joy
  sudo chown -R vagrant:vagrant /usr/local/lib/janet

  echo "=== Setting default editor to vim"
  sudo echo "export EDITOR='vim'" >> /home/vagrant/.bashrc
  sudo chown vagrant:vagrant /home/vagrant/.bashrc

  echo "*********************"
  echo "PROVISIONING FINISHED"
  echo "*********************"
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "joy"
  config.vm.network :forwarded_port, guest: 9001, host: 9001

  config.vm.provision "shell", inline: $script, privileged: false
end
