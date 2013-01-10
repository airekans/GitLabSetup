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


