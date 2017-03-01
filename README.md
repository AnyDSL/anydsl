# AnyDSL
Meta project to quickly build dependencies

## Building

```bash
git clone git@github.com:AnyDSL/anydsl.git
cd anydsl
cp config.sh.template config.sh
./setup.sh
```
You may also want to fine-tune ```config.sh```.
In particular, if you don't have a GitHub account with a working [SSH key](https://help.github.com/articles/generating-ssh-keys), set ```: ${HTTPS:=true}```.
This will clone all repositories via https.

See [Build Instructions](https://github.com/AnyDSL/anydsl/wiki/Build-Instructions) for more information.
