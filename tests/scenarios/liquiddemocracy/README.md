This is the command line that I run the tests from DAO/tests directory. They take more than 5 minutes tu run..

python test.py --solc /usr/local/bin/solc --geth /Users/jbaylina/git/go-ethereum/build/bin/geth --verbose  --scenario liquiddemocracy --clean-chain --users-num 6 --deploy-creation-seconds 60

I use geth commit: 18580e1  // It's a not very stable version, but it more or less works.

