#! /bin/sh

# Refer to http://dlaxar.blogspot.co.at/2012/06/installing-gitlab-with-gitolite-on.html
## Please run the following command as root
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

yum -y install mysql-devel readline readline-devel ncurses-devel gdbm-devel glibc-devel tcl-devel openssl-devel curl-devel expat-devel db4-devel byacc gitolite sqlite-devel gcc-c++ libyaml libyaml-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libicu libicu-devel system-config-firewall-tui python-devel redis

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


#### Data settings
#### Please refer to doc/install/databases.md in GitLab.

#### GitLab settings
# We'll install GitLab into home directory of the user "gitlab"
cd /data/gitlab

# Clone GitLab repository
sudo -u gitlab -H git clone https://github.com/gitlabhq/gitlabhq.git gitlab

# Go to gitlab dir 
cd /data/gitlab/gitlab

# Checkout to stable release
sudo -u gitlab -H git checkout 4-0-stable

### Configure it
cd /data/gitlab/gitlab

# Copy the example GitLab config
sudo -u gitlab -H cp config/gitlab.yml.example config/gitlab.yml

# Make sure to change "localhost" to the fully-qualified domain name of your
# host serving GitLab where necessary
## remember to change the port number, repos_path and hooks_path
#### TODO: sed command to change the file directly.
sudo -u gitlab -H vim config/gitlab.yml

# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R gitlab log/
sudo chown -R gitlab tmp/
sudo chmod -R u+rwX  log/
sudo chmod -R u+rwX  tmp/

# Copy the example Unicorn config
# Remember to change the app_dir
#### TODO: sed command to change the file directly.
sudo -u gitlab -H cp config/unicorn.rb.example config/unicorn.rb
sudo -u gitlab -H vim config/unicorn.rb

# Mysql
#### TODO: sed command to change the file directly.
sudo -u gitlab cp config/database.yml.mysql config/database.yml
sudo -u gitlab -H vim config/database.yml

## Install Gems
cd /data/gitlab/gitlab

sudo gem install charlock_holmes --version '0.6.9'

# For mysql db
sudo -u gitlab -H bundle install --deployment --without development test postgres

## Setup GitLab Hooks
sudo cp ./lib/hooks/post-receive /data/git/.gitolite/hooks/common/post-receive
sudo chown git:git /home/git/.gitolite/hooks/common/post-receive

## Initialise Database and Activate Advanced Features
sudo -u gitlab -H bundle exec rake gitlab:app:setup RAILS_ENV=production

## Check Application Status
sudo -u gitlab -H bundle exec rake gitlab:env:info RAILS_ENV=production
# sudo -u gitlab -H bundle exec rake gitlab:check RAILS_ENV=production

#### Install Init Script
sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab -P /etc/init.d/
sudo chmod +x /etc/init.d/gitlab

# Make GitLab start on boot:
sudo chkconfig --add gitlab
sudo chkconfig --level 2345 gitlab on

## Start your GitLab instance:
## start redis first
sudo service redis start
sudo service gitlab start

# Check whether the installation is okay
sudo -u gitlab -H bundle exec rake gitlab:check RAILS_ENV=production

#### Install Nginx
sudo yum install nginx

# Site Configuration
sudo mkdir -p /etc/nginx/sites-available/
sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/nginx/gitlab -P /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/conf.d/gitlab.conf

# Change **YOUR_SERVER_IP** and **YOUR_SERVER_FQDN**
# to the IP address and fully-qualified domain name
# of your host serving GitLab
sudo vim /etc/nginx/conf.d/gitlab.conf

sudo /etc/init.d/nginx restart
