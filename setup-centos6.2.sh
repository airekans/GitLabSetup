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
