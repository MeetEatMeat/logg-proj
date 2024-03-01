# LOGARITHM GAMES
## This is a LOGG token of Logarithm Games Project

To run the project copy and paste into console:

````
forge install

foundryup

forge build

forge test -vvvv
````
Next step to deploy the project is create `.env` file into the root of the project and fill it with following:

````
BSC_TESTNET_RPC=""
BSC_MAINNET_RPC=""
PRIV_KEY=
ETHERSCAN_API_KEY=""
````
Only the `PRIV_KEY` shouldn't use with ""

Now you should load your `.env` file:

````
source .env
````

Then, to run the project in simulation mode run the following:

````
forge script script/LOGGToken.s.sol:LOGGScript --rpc-url $BSC_TESTNET_RPC
````

To deploy the project to devnet run:

````
forge script script/LOGGToken.s.sol:LOGGScript --rpc-url $BSC_TESTNET_RPC --broadcast -vvvv --private-keys $PRIV_KEY 
````

To deploy the project to devnet and verify contracts run:

````
forge script script/LOGGToken.s.sol:LOGGScript --rpc-url $BSC_TESTNET_RPC --etherscan-api-key $ETHERSCAN_API_KEY --broadcast --verify -vvvv --private-keys $PRIV_KEY
````

And finally to deploy the project to Mainnet run following:

````
forge script script/LOGGToken.s.sol:LOGGScript --rpc-url $BSC_MAINNET_RPC --etherscan-api-key $ETHERSCAN_API_KEY --broadcast --verify -vvvv --private-keys $PRIV_KEY
````



