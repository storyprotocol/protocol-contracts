
async function main(args, hre) {
    const { ethers } = hre;
    const { id, keccak256, solidityPack } = ethers.utils;
    const BigNumber = ethers.BigNumber;
    const { namespace } = args;
    // See https://eips.ethereum.org/EIPS/eip-7201
    const result = keccak256(
        solidityPack(
            ["bytes32"],
            [
                BigNumber.from(id(namespace)).sub("1")
            ]
        )
    );
    console.log(result);
    return result;
}

module.exports = main;
