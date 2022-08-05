# Solidity Contract to Sell multiple NFTs to users via your self erc20-token or with ethereum

This repository has below 3 Solidity Files in contract folder :--

1. NFT.sol : This is an ERC721 contract File for creating an NFT contract with some overridden methods that allows owner to change parameters like name, symbol, tokenURI etc.

2. opener.sol : This is a mediator contract that allows NFT sales to users via own ERC20 Token.
this contract also allows the owner to set up a royalty fee against each NFT purchase. A percentage of this fee is deducted from purchase amount and sent to a predefined Fee Address at the time of purchase.

This Opener contract can be used to initiate sale of different NFT contracts. The owner has to setup the NFT contract address, name and available NFT count in the "setOFC" function of the contract.

openMagicBox : This is the main function that enable the purchase to happen, it accepts below arguments :--

address _to                 : Purchase Address
uint256[] calldata _type,   : array of NFT Contract plans (setup using setOFC function)
uint256[] calldata _ids,    : array of tokn Ids 
string[] calldata _uris     : array of tokenUris
uint256 _erc20              : amount of tokens to charge
uint256 _nonce              : unique nonce
bytes calldata signature    : owner signature of all above aguments for verification

The contract uses a signature verification process , the signature should be created by the contract owner and should contain all above parameters, this is to ensure that the call to this contract function is initiate with owner aggreance.

Once the signature is verified, amount of tokens are debited from purchasers account and credited to Fee_Address.

User must give ERC20 Approval to this opener contract first.

3. trade.sol : This contract enable NFT sales via Ethereum or BNB.

It also uses signature verification to ensure that the request is from a valid source and after verification and validation, it transfer the sent ETH value to NFT creator and the NFT to the purchaser.