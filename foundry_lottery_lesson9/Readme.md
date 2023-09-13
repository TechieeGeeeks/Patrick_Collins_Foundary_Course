# Proveably Random Raffle Contract 

## What code will do?
This code is to create a proveably random smart contract for lottery.

## What we want it to do?

1) Users can enter in a lottery by paying for a ticket.
2) The ticker fees are going to the winner during the draw.
3) After X amount of time, the lottery will automatically draw a winner. (All THis tuff will hapen automtically, programmatically)
4) Using chainLink VRF & Chainlink Automation
    - Chainking VRF -> Randomness
    - Chainkink Automation -> Time Based Trigger

## Tests!

1. Write some deploy scripts 
2. write our tests
   1. work on local chain
   2. Forked Testnet
   3. Forked Mainnet

## How to write Deploy scripts?
1. First prepare HelperConfig.s.sol contract which will inherit Script
2. Create struct for NetworkConfig which will contain all the parameters that you want to pass to contract in constructor
3. Then prepare functions which will set the values of struct for particular chain and that dunction should return this networkConfig Struct for that particular chain
    EXAMPLE:  
    1. getSepoliaEthConfig()
    2. getOrCreateNetworkConfig()
   
4.  Then in constructor put checks which network we deploying too 
    1.  if chain id is of sepolias then we will call particular getSepoliaEthConfig() function which will set up the values of activeNetworkConfig to sepolias values
    2.  For anvil chain we have to setup our own mocks cause we wont have already pre deployed contracts avaialbe like sepolia
        1.  For such case we have mock contract present in (lib ->  chainlink-brownie-contracts -> contracts -> src -> v0.8 -> mocks)
        Just import this contracts in out HelperConfig Will help us deploying on AnvilChain

5. Import HelperConfig in Deploy Script and use run function to deploy our contract 