#! /bin/sh

## Please run the following command as root

yum -y install readline readline-devel ncurses-devel gdbm-devel glibc-devel tcl-devel openssl-devel curl-devel expat-devel db4-devel byacc gitolite sqlite-devel gcc-c++ libyaml libyaml-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libicu libicu-devel system-config-firewall-tui python-devel redis

cd
mkdir -p tmp
cd tmp

# Install Ruby
curl -O http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p0.tar.gz
tar xzvf ruby-1.9.3-p0.tar.gz
cd ruby-1.9.3-p0

./configure --enable-shared --disable-pthread

make && make install

# If you cannot locate gem, use "whereis gem" to find out it location
gem update --system
gem update
gem install bundler
gem install rails

# Add users git and gitlab
adduser --system --shell /bin/sh -c 'Git Version Control' --home /data/git git
mkdir -p /data/git
chown git:git /data/git

adduser -c 'GitLab' --home /data/git gitlab
mkdir -p /data/gitlab
chown gitlab:gitlab /data/gitlab

usermod -a -G git gitlab
sudo -u gitlab -H ssh-keygen -q -N '' -t rsa -f /data/gitlab/.ssh/id_rsa

# gitolite settings
cd /data/git
sudo -u git -H git clone -b gl-v320 https://github.com/gitlabhq/gitolite.git /data/git/gitolite

# Add Gitolite scripts to $PATH
sudo -u git -H mkdir /data/git/bin
sudo -u git -H sh -c 'printf "%b\n%b\n" "PATH=\$PATH:/data/git/bin" "export PATH" >> /data/git/.profile'
sudo -u git -H sh -c 'gitolite/install -ln /data/git/bin'

# Copy the gitlab user's (public) SSH key ...
sudo cp /data/gitlab/.ssh/id_rsa.pub /data/git/gitlab.pub
sudo chmod 0444 /data/git/gitlab.pub

# ... and use it as the admin key for the Gitolite setup
sudo -u git -H sh -c "PATH=/data/git/bin:$PATH; gitolite setup -pk /data/git/gitlab.pub"

# Make sure the Gitolite config dir is owned by git
sudo chmod 750 /data/git/.gitolite/
sudo chown -R git:git /data/git/.gitolite/

# Make sure the repositories dir is owned by git and it stays that way
sudo chmod -R ug+rwXs,o-rwx /data/git/repositories/
sudo chown -R git:git /data/git/repositories/

echo "Host localhost
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null" | sudo tee -a /etc/ssh/ssh_config

### Test if everything is OK
# Clone the admin repo so SSH adds localhost to known_hosts ...
# ... and to be sure your users have access to Gitolite
sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

# If it succeeded without errors you can remove the cloned repo
sudo rm -rf /tmp/gitolite-admin
