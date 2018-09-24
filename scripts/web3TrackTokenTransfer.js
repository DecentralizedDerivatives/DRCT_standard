require('dotenv').config()
const Web3 = require('web3');
const confirmEtherTransaction = require('./web3Confirm');
const TOKEN_ABI = artifacts.require("Wrapped_Ether");//how to create abi

var accessToken = process.env.INFURA_ACCESS_TOKEN;
var _wrapped= "0x6248cb8a316fc8f1488ce56f6ea517151923531a";//rinkeby new dud

function watchTokenTransfers() {
  // Instantiate web3 with WebSocketProvider
 // const web3 = new Web3(new Web3.providers.WebsocketProvider('wss://rinkeby.infura.io/ws'))
  // Instantiate web3 with WebSocketProvider
  const web3 = new Web3("https://rinkeby.infura.io/"+ accessToken)

  // Instantiate token contract object with JSON ABI and address
  const tokenContract = new web3.eth.Contract(
    Wrapped_ABI, _wrapped,
    (error, result) => { if (error) console.log(error) }
  )

  // Generate filter options
  const options = {
    fromBlock: 'latest'
  }

  // Subscribe to Transfer events matching filter criteria
  tokenContract.events.Transfer(options, async (error, event) => {
    if (error) {
      console.log(error)
      return
    }

    // Initiate transaction confirmation
    confirmEtherTransaction(event.transactionHash)

    var link = "".concat('<https://rinkeby.etherscan.io/address/',_wrapped,'>' );
    var ar = [_from, _to, _amount, txHash, link];
    console.log(ar.join(', '));

    return
  })
}

