/* global ethers */

const { ethers } = require('hardhat')

async function main() {
    // Deploy Facet contract.
    const CONTRACT_NAME = '';
    const Facet = await ethers.getContractFactory(CONTRACT_NAME)
    const facet = await Facet.deploy()
    await facet.waitForDeployment()
    console.log(`Facet contract ${CONTRACT_NAME} is deployed to: `, await facet.getAddress())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});