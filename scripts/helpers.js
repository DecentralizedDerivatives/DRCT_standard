const Web3 = require('web3');

const getWeb3 = () => {
	const myWeb3 = new Web3(web3.currentProvider)
	return myWeb3
}

function getWeb3() {
	const myWeb3 = new Web3(web3.currentProvider)
	return myWeb3
}

const getContractInstance = (web3) => (contractName, from) => {
	const artifact = artifact.require(contractName)

	const instance = new web3.eth.Contract(artifact.abi, {
		data: artifact.bytecode,
		gas: 5000000,
		from
	})
}

const getExistContract = (web3) => (contractName, contractAddress) => {
	const artifact = artifact.require(contractName)

	const instance = new web3.eth.Contract(artifact.abi, contractAddress)
}

module.exports = {getWeb3, getContractInstance, getExistContract}