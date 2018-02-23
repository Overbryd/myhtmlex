#!/bin/sh

start_dir=`pwd`

abort()
{
  cd $start_dir
  exit 1
}

trap 'abort' 0
set -e

make clean
test -d package-test || mkdir package-test
rm -rf package-test/*

mkdir package-test/myhtmlex-local
mix hex.build
mv myhtmlex-*.tar package-test/myhtmlex-local/
cd package-test/myhtmlex-local
tar -xf *.tar
tar -xzf *.tar.gz
cd ..
mix new myhtmlex_pkg_test
cd myhtmlex_pkg_test

# Default operation
sed -i "" -e 's/^.*dep_from_hexpm.*$/      {:myhtmlex, path: "..\/myhtmlex-local"}/' mix.exs
mix deps.get
mix compile
mix run -e 'IO.inspect {"html", [], [{"head", [], []}, {"body", [], ["foo"]}]} = Myhtmlex.decode("foo")'

# Nif operation
sed -i "" -e 's/^.*myhtmlex-local.*$/      {:myhtmlex, path: "..\/myhtmlex-local", runtime: false}/' mix.exs
echo "config :myhtmlex, mode: Myhtmlex.Nif" >> config/config.exs
mix run -e 'IO.inspect {"html", [], [{"head", [], []}, {"body", [], ["foo"]}]} = Myhtmlex.decode("foo")'

trap : 0

cd $start_dir
echo "ok"

