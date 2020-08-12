$script = <<SCRIPT
  echo "*** Updating packages"

  sudo apk update

  echo "*** Installing system dependencies"

  sudo apk add --no-cache build-base curl-dev git vim

  echo "*** Installing janet"

  sudo git clone https://github.com/janet-lang/janet.git /tmp/janet
  cd /tmp/janet
  sudo make all test install
  sudo chmod 777 /usr/local/lib/janet

  echo "*** Installing joy"

  sudo jpm install joy
  sudo chown -R vagrant:vagrant /usr/local/lib/janet

  echo "*** Setting default editor to vim"
  sudo echo "export EDITOR='vim'" >> /home/vagrant/.bashrc
  sudo chown vagrant:vagrant /home/vagrant/.bashrc

  echo "*********************"
  echo "PROVISIONING FINISHED"
  echo "*********************"
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "alpine/alpine64"
  config.vm.hostname = "joy"
  config.vm.network :forwarded_port, guest: 9001, host: 9001

  config.vm.provision "shell", inline: $script, privileged: false
  config.vm.synced_folder ".", "/vagrant"
end
