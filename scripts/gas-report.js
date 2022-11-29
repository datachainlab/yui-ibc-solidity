const csv = require("csv-stringify");
const fs = require("fs");
const InputDataDecoder = require("ethereum-input-data-decoder");

const Migrations = artifacts.require("Migrations");
const IBCCommitment = artifacts.require("IBCCommitment");
const IBCMsgs = artifacts.require("IBCMsgs");
const IBCClient = artifacts.require("IBCClient");
const IBCConnection = artifacts.require("IBCConnection");
const IBCChannel = artifacts.require("IBCChannel");
const OwnableIBCHandler = artifacts.require("OwnableIBCHandler");
const MockClient = artifacts.require("MockClient");
const IBFT2Client = artifacts.require("IBFT2Client");
const SimpleToken = artifacts.require("SimpleToken");
const ICS20Bank = artifacts.require("ICS20Bank");
const ICS20TransferBank = artifacts.require("ICS20TransferBank");

const getContracts = async () => {
  let contracts = {};

  for (const definition of [
    Migrations,
    IBCCommitment,
    IBCMsgs,
    IBCClient,
    IBCConnection,
    IBCChannel,
    OwnableIBCHandler,
    MockClient,
    IBFT2Client,
    SimpleToken,
    ICS20Bank,
    ICS20TransferBank,
  ]) {
    const contract = await definition.deployed();
    contracts[contract.address] = {
      name: definition._json.contractName,
      decoder: new InputDataDecoder(contract.abi),
    };
  }

  return contracts;
}

module.exports = async (callback) => {
  try {
    const height = await web3.eth.getBlockNumber();

    const contracts = await getContracts();

    let data = [];

    for (let i = 1; i <= height; i++) {
      const block = await web3.eth.getBlock(i);
      if (block.transactions.length === 0) {
        continue;
      }

      for (const txHash of block.transactions) {
        const receipt = await web3.eth.getTransactionReceipt(txHash);

        const callType = receipt.contractAddress ? "deploy" : "call";

        let contractName = "";
        let functionName = "";
        let argNames = "";
        let args = "";
        if (callType === "deploy") {
          const { name, _ } = contracts[receipt.contractAddress];
          contractName = name;
        } else if (callType === "call") {
          const tx = await web3.eth.getTransaction(txHash);
          const contract = contracts[tx.to];
          if (contract) {
            const { name, decoder } = contract;
            const input = decoder.decodeData(tx.input);
            contractName = name;
            functionName = input.method;
            argNames = input.names;
            args = input.inputs;
          } else {
            console.warn(`unknown contract:${tx.to}`)
            contractName = "UnknownContract"
          }

        }

        data.push({
          blockHeight: receipt.blockNumber,
          transactionIndex: receipt.transactionIndex,
          txHash: receipt.transactionHash,
          status: receipt.status,
          from: receipt.from,
          to: receipt.to,
          contractAddress: receipt.contractAddress,
          gasUsed: web3.utils.hexToNumber(receipt.gasUsed),
          callType,
          contractName,
          functionName,
          argNames,
          args,
        });
      }
    }

    csv.stringify(data, { header: true }, (err, output) => {
      if (err) {
        return err;
      }
      fs.writeFileSync("report.csv", output);
      callback();
    });
  } catch (e) {
    callback(e);
  }
};
