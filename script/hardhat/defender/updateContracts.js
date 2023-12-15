const loadDeployment = require('../loadDeployment.js');
import { Defender } from '@openzeppelin/defender-sdk';
const creds = { apiKey: process.env.DEFENDER_API_KEY, apiSecret: process.env.DEFENDER_API_SECRET };


async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const client = new Defender(creds);


}

module.exports = main;
