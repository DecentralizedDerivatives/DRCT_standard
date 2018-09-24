

const Web3 = require('web3')
const validateTransaction = require('./web3Validate')
const confirmEtherTransaction = require('./web3Confirm')
const TOKEN_ABI = require('./abi')

var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;

function watchEtherTransfers() {
  // Instantiate web3 with WebSocket provider
  const web3 = new Web3(new Web3.providers.WebsocketProvider("https://rinkeby.infura.io/"+ accessToken))

  // Instantiate subscription object
  const subscription = web3.eth.subscribe('pendingTransactions')

  // Subscribe to pending transactions
  subscription.subscribe((error, result) => {
    if (error) console.log(error)
  })
    .on('data', async (txHash) => {
      try {
        // Instantiate web3 with HttpProvider
        const web3Http = new Web3("https://rinkeby.infura.io/"+ accessToken)

        // Get transaction details
        const trx = await web3Http.eth.getTransaction(txHash)

        const valid = validateTransaction(trx)
        // If transaction is not valid, simply return
        if (!valid) return


        // Initiate transaction confirmation
        confirmEtherTransaction(txHash)

        // Unsubscribe from pending transactions.
        subscription.unsubscribe()
      }
      catch (error) {
        console.log(error)
      }
    })
}

function watchTokenTransfers() {
  // Instantiate web3 with WebSocketProvider
  const web3 = new Web3(new Web3.providers.WebsocketProvider("https://rinkeby.infura.io/"+ accessToken))

  // Instantiate token contract object with JSON ABI and address
  const tokenContract = new web3.eth.Contract(
    TOKEN_ABI, _wrappe,
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

module.exports = {
  watchEtherTransfers,
  watchTokenTransfers
}