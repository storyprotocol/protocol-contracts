require("dotenv").config();
const loadDeployment = require('../loadDeployment.js');
const { Defender } = require('@openzeppelin/defender-sdk');


function getAbi(contractName) {
    const abi = require(`../../../out/${contractName}.sol/${contractName}.json`).abi;
    return JSON.stringify(abi);
}

function getStep(defenderContractId, contract, functionName, functionInputs) {
    if (functionName === 'grantRole') {
        return {
            contractId: defenderContractId,
            metadata: {
                action: 'grantRole',
                role: functionInputs[0],
                account: functionInputs[1],
            },
            type: 'access-control',
        }
    } else {
        const inputs = contract.interface.getFunction(functionName).inputs
            .map((input) => {
                return { type: input.type, name: input.name };
            });
        return {
            contractId: defenderContractId,
            targetFunction: {
                name: functionName,
                inputs: inputs,
            },
            functionInputs: functionInputs,
            type: 'custom',
        }
    }
}

/// @dev Create a Defender proposal, using the Defender SDK
/// This script will read the proposal from a file in the script/proposals folder
/// The proposal file should export an object with the following properties:
/// - title: string
/// - description: string
/// - network: string
/// - steps: array of objects with the following properties:
///   - contractName: string
///   - functionName: string
///   - functionInputs: array of function inputs
/// The script will then create a Defender proposal with the given steps
/// The proposal will be created on the network specified in the proposal file
/// The script will use the Defender API key and secret specified in the .env file
/// The script will use the Defender multisig address specified in the .env file
/// The file may contain multiple actions, which will be executed in order but batch into a single
/// transaction to minimize signing processes for the multisig.
async function main(args, hre) {
    const creds = { apiKey: process.env.DEFENDER_API_KEY, apiSecret: process.env.DEFENDER_API_SECRET };
    const client = new Defender(creds);
    const { ethers, network } = hre;
    const { contracts } = await loadDeployment(hre);

    const proposalInput = require(`${__dirname}/proposals/${args.proposalFileName}.js`);

    if (network.name !== proposalInput.network) {
        throw new Error(`Network ${network.name} does not match proposal network ${proposalInput.network}`);
    }
    const safeMultisig = process.env.SEPOLIA_MULTISIG_ADDRESS;

    const defenderContracts = (await client.proposal.listContracts()).filter((c) => c.network === network.name);
    if (defenderContracts.length === 0) {
        throw new Error(`No contracts found in Defender for network ${network.name}`);
    }

    const requiredContractNames = proposalInput.steps.map((step) => step.contractName);
    const filteredContracts = defenderContracts
        .filter((c) => requiredContractNames.includes(c.name))
        .map((c) => {
            return { name: c.name, contractId: c.contractId, address: c.address, abi: getAbi(c.name), network: network.name };
        });

    const steps = proposalInput.steps
        .map((step) => getStep(`${network.name}-${contracts[step.contractName].address}`, contracts[step.contractName], step.functionName, step.functionInputs));

    const { url } = await client.proposal.create({
        proposal: {
            contract: filteredContracts,
            title: proposalInput.title,
            description: proposalInput.description,
            type: 'batch',
            via: safeMultisig,
            viaType: 'Safe',
            metadata: {}, // Required field but empty
            steps,
        },
    });
    console.log(`Proposal created: ${url}`);
}

module.exports = main;
