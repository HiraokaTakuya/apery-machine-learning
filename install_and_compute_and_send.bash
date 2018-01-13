#!/bin/bash

REGION=eu-west-1
BUCKETNAME=apery-machine-learning-v1.24.0

TEACHERNODES=10000000
ROOTS=../../apery-machine-learning-resources/roots.hcp

# non-interactive upgrade
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
sudo -E apt-get -qy update
sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade

sudo apt-get install g++ make git mono-complete -y

git submodule init
git submodule update --depth=1

git clone https://github.com/HiraokaTakuya/aws_put_object.git
git clone -b develop/machine-learning https://github.com/HiraokaTakuya/apery.git

cd apery
git submodule init
git submodule update --depth=1
(cd src && make bmi2 -j && mv apery ../bin)
(cd utils/shuffle_hcpe && make && mv shuffle_hcpe ../../bin)
cd bin
cp ../../aws_put_object/aws_put_object/bin/Release/* .

if [ $(md5sum ../../apery-machine-learning-resources/roots.hcp | cut -d " " -f 1) = "8d052340bbbf518d05d27f26fd2861a1" ]; then
    :
else
    exit
fi

if [ $(md5sum 20171106/KPP.bin | cut -d " " -f 1) = "2e0481cc75401eafeb7379ef514272e1" ]; then
    :
else
    exit
fi

if [ $(md5sum 20171106/KKP.bin | cut -d " " -f 1) = "26f545b7dd09b317483deb3cd4f9052f" ]; then
    :
else
    exit
fi

while :
do
    OUTPUTFILENAME=out_`od -vAn -N8 -tu8 < /dev/urandom | tr -d "[:space:]"`.hcpe
    SHUFOUTPUTFILENAME=shuf${OUTPUTFILENAME}
    ./apery make_teacher $ROOTS $OUTPUTFILENAME $(nproc) $TEACHERNODES
    ./shuffle_hcpe $OUTPUTFILENAME $SHUFOUTPUTFILENAME && rm $OUTPUTFILENAME && mono ./aws_put_object.exe $BUCKETNAME $SHUFOUTPUTFILENAME && rm $SHUFOUTPUTFILENAME
done
