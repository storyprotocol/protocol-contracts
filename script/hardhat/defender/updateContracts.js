const loadDeployment = require('../loadDeployment.js');


async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    
    
}

module.exports = main;
