<p align="center">
  <a href='https://www.daxia.us/'>
    <img src= './public/DarkText_IconColor.png' width="300" height="100" alt='Daxia.us' />
  </a>
</p>

<p align="center">
  <a href='https://dapp.daxia.us/'>
    <img src= ./public/DApp-Daxia-blue.svg alt='Slack' />
  </a>
  <a href='https://deriveth.slack.com/'>
    <img src= ./public/Chat-Slack-blue.svg alt='Slack' />
  </a>
  <a href='https://t.me/daxiachat'>
    <img src= ./public/Chat-Telegram-blue.svg alt='Telegram DaxiaChat' />
  </a>
  <a href='https://twitter.com/DaxiaOfficial'>
    <img src= 'https://img.shields.io/twitter/url/http/shields.io.svg?style=social' alt='Twitter DaxiaOfficial' />
  </a> 
  <img src= ./public/License-MIT-blue.svg alt='MIT License' /> 
</p>
<p align="center">
      Tokenized Derivatives on Ethereum
</p>


## Table of Contents

* [Instructions for quick start with Truffle Deployment](#Quick-Deployment)
   * [Detailed documentation for self setup](./SetupYourOwnDRCT.md)
* [Overview](#Overview)
   * [In-Depth Overview](./InDepthOverview.md)
* [Useful Links](#UsefulLinks)

<details><summary>Contributing information</summary>

   * [Maintainers](#Maintainers)
   * [How to Contribute](#how2contribute)
   * [Copyright](#copyright)
 </details>

# Dynamic Rate Cash Transaction Tokens
### Instructions for quick start with Truffle Deployment <a name="Quick-Deployment"> </a>  

Follow the steps below to launch the Factory, Oracle and dependency contracts using Truffle. 

Clone the repo, cd into it, and then:

    $ npm install

    $ truffle compile

    $ truffle migrate

    $ truffle exec /scripts/Admin_01_setup.js

    $ truffle exec /scripts/Admin_02_newfactory_new_oracle.js

    $ truffle exec /scripts/Admin_07_contract_setup.js

You're ready to create DRCT tokens and contracts!

Step by step instructions on setting up your own DRCT contracts without truffle are available here: [Detailed documentation for self setup](./SetupYourOwnDRCT.md)

## Overview <a name="overview"> </a> 
Dynamic Rate Cash Transaction (DRCT) Tokens are standardized contracts for trading risk and hedging exposure to underlying reference rates. DRCT token contracts are a risk management tool for cryptocurrency users that allow to long and/or short cryptocurrencies. Being long is a position where, if the price goes up, you make money and if it goes down, you lose money. The traditional way of being long an asset would be to simply own it. Being short is a position where if the price goes down you make money and if it goes up you lose money. If you own an asset and short it, your held asset loses value but your short position makes you money, helping you mitigate the price volatility risk. 

DRCT contracts can provide more flexibility in terms of rate sensitivity and trading mechanisms than traditional OTC derivatives and allow for custom hedging and trading strategies not provided by traditional investments in cryptocurrency without minimum thresholds and with no intermediaries.

Additionally, DRCT tokens allow users to long or short assets that are non-native to Ethereum (like Bitcoin, Monero, Stellar, etc...) with Ether or any other ERC20 token.  

<p align="center">
<img src="./public/CreatingContract.png" width="300" height="400" alt="Picture of contract creating short and long tokens">
</p>
DRCT contracts start with a "creator" and are given a rate/duration/start date combination. Ether is locked as collateral in the smart contract by the creator.  Short and Long Tokens are issued to the creator and represent the payouts of the contract. These tokens can be posted for sale on the Daxia Bulletin or with partner exchanges. On the end date of the contract, the tokens are paid out from the collateral (to whoever is holding them at that point in time) based on the change in the underlying rate. 

All DRCT tokens ascribe to ERC20 specifications and can trade on any centralized or decentralized exchange. 

A deep dive in methododology is available here: [In-Depth Overview](./InDepthOverview.md)

## Useful Links <a name="UsefulLinks"> </a>  

If you have questions, ask us on Slack: https://deriveth.slack.com/

DAPP:  http://dapp.daxia.us/ 

Oracle Methodology can be found at: https://github.com/DecentralizedDerivatives/Public_Oracle

Metamask - www.metamask.io 

Truffle - http://truffleframework.com/

#### Maintainers <a name="maintainers"> </a> 
[@themandalore](https://github.com/themandalore)
<br>
[@brendaloya](https://github.com/brendaloya) 

#### How to Contribute<a name="how2contribute"> </a>  
Join our slack, shoot us an email or contact us: [<img src="./public/slack.png" width="24" height="24">](https://deriveth.slack.com/)
[<img src="./public/telegram.png" width="24" height="24">](https://t.me/daxiachat)
[<img src="./public/discord.png" width="24" height="24">](https://discordapp.com/invite/xtsdpbS)

Any contributions are welcome!


#### Copyright <a name="copyright"> </a> 

DDA Inc. 2018