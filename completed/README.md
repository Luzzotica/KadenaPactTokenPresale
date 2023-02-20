# Overview

This repo contains the following:

1. A smart contract that defines a fungible token on Kadena using Pact
2. A smart contract that allows developers to sell their token and pay it out
3. A website that links with the token sale contract and lets people reserve tokens in the sale

Both smart contracts are completely tested.

Everything is generic and can be redeployed for you own token!  

Checkout what the website looks like [here](https://pact-token-sale.luzzotica.xyz/).

This repo was created, and is used by the Pact Token Sale course created by Sterling Long (Luzzotica).  
If you'd like to learn how to build this all from scratch so you can kickstart your development career using Pact on Kadena, go [purchase the course](https://www.luzzotica.xyz/offers/ZJQYRFF6/checkout)!

# To Use

## Update the Smart Contracts and Deploy Data

First thing for you to do is update the module names in each of the smart contracts: `n_532057688806c2750b8907675929ffb2488e93c0.swag-token` and `n_532057688806c2750b8907675929ffb2488e93c0.swag-token-sale` are both taken.  

Keep in mind that when you do this, the tests will no longer work unless you update the references to the smart contracts there.

The next thing to do is update the `deploy-env-data.json` to have your token's information in it. This file defines your tokenomics, and also how many tokens are sold in your sale, along with whitelisted individuals, and tiers defining a prices with start and end times.

Before you deploy, you must first modify this data to match what you need.

## Deploy Smart Contracts

Use [KadenaKode](https://kadenakode.luzzotica.xyz/) to deploy the contracts to either testnet or mainnet.  
  1. Copy the `deploy-env-data.json` into the **Env Data** section
  2. Copy the `swag-token.pact` smart contract into the **Code** section
  3. Link your wallet
  4. Click sign local, if no errors were thrown, click send, otherwise, fix the errors.

## Deploy Website

To use the website, please read the README found in the website folder itself.