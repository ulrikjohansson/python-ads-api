{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/197ddbced2ae72efbef0f5f8838a7ad3fbd986eb.tar.gz") {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python38Full
    pkgs.python38Packages.pip
    pkgs.python38Packages.virtualenv
    pkgs.python38Packages.poetry
    pkgs.postgresql_12
    
  ];

  shellHook = ''
  export PGHOST=$HOME/postgres
  export PGDATA=$PGHOST/data
  export PGDATABASE=postgres
  export PGLOG=$PGHOST/postgres.log

  mkdir -p $PGHOST

  if [ ! -d $PGDATA ]; then
    initdb --auth=trust --no-locale --encoding=UTF8
  fi

  if ! pg_ctl status
  then
    pg_ctl start -l $PGLOG -o "--unix_socket_directories='$PGHOST'"
  fi

  if [ ! -d app/.venv/lib/python3.8/site-packages/asyncpg ]; then
    poetry new app --name routers
    cd app
    poetry config virtualenvs.in-project true
    poetry env use python3.8
    poetry add fastapi --extras all
    poetry add aiomisc --extras uvloop
    poetry add asyncpg
    poetry run uvicorn main:app --reload
  else
    echo "Project is already setup.. Starting app now"
    cd app
    poetry run uvicorn main:app --reload
  fi

'';
}
