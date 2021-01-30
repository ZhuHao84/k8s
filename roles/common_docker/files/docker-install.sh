if [[ $(ssh -l root "$1" 'docker -v') == *" 1.7."* ]]; then
  echo 'Docker version 1.7!'
else
  echo 'Docker version not 1.7!'
fi