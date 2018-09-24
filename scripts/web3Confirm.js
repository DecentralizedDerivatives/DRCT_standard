const Web3 = require('web3')
require('dotenv').config()


var accessToken = process.env.INFURA_ACCESS_TOKEN;
var _wrapped= "0x6248cb8a316fc8f1488ce56f6ea517151923531a";//rinkeby new dud

async function getConfirmations(txHash) {
  try {
    // Instantiate web3 with HttpProvider
    const web3 = new Web3("https://rinkeby.infura.io/"+ accessToken)

    // Get transaction details
    const trx = await web3.eth.getTransaction(txHash)

    // Get current block number
    const currentBlock = await web3.eth.getBlockNumber()

    // When transaction is unconfirmed, its block number is null.
    // In this case we return 0 as number of confirmations
    return trx.blockNumber === null ? 0 : currentBlock - trx.blockNumber
  }
  catch (error) {
    console.log(error)
  }
}

function confirmEtherTransaction(txHash, confirmations = 10) {
  setTimeout(async () => {
    // Get current number of confirmations and compare it with sought-for value
    const trxConfirmations = await getConfirmations(txHash)
    console.log('Transaction with hash ' + txHash + ' has ' + trxConfirmations + ' confirmation(s)')

    if (trxConfirmations >= confirmations) {
      // Handle confirmation event according to your business logic

      console.log('Transaction with hash ' + txHash + ' has been successfully confirmed')

      return
    }
    // Recursive call
    return confirmEtherTransaction(txHash, confirmations)
  }, 30 * 1000)
}

module.exports = confirmEtherTransaction