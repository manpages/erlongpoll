#!/bin/bash
if [[ $EUID -ne 0 ]]; then
	echo "run me as root plz"
	echo "kthxbye"
	exit 1
fi

echo "icanhaz: git, erlang, gcc, make, autoconf"
cd ..

echo "YAWS! incoming!"
git clone git://github.com/klacke/yaws.git
cd yaws
autoconf; ./configure; make; make local_install
cd ..
wget http://memoricide.very.lv/yaws.conf
mkdir logs

touch Emakefile
echo "{\"erlongpoll/example/src/*\", [{outdir, \"erlongpoll/example/ebin\"}]}." >> Emakefile

touch erl.sh
echo "erl -name push_example@myhost -pa yaws/ebin/ erlongpoll/example/ebin" > erl.sh
chmod 775 ./erl.sh

mkdir erlongpoll/example/ebin
mkdir erlongpoll/example/tmp/hehe
echo ""
echo "I'm tired. do 'chgrp -R <group> .' and 'chown -R <user> .' yourself"
echo "And you might like to edit ./yaws.conf and ./erl.sh"
echo "Put something like metabb@<your_hostname> after -name key in ./erl.sh"
echo ""
echo "To get it finally working run erl.sh"
echo "> application:start(yaws)."
echo "> pollbox:start()."
