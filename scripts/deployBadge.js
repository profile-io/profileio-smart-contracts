/* global ethers */

const { ethers } = require('hardhat')

async function main() {

    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const Badge = await ethers.getContractFactory('Badge')
    const badge = await Badge.deploy(
        "https://api.pudgypenguins.io/lil/",
        "Profile.io Badge",
        "PRFL",
        0,
        owner.getAddress()
    )
    await badge.waitForDeployment()
    console.log('Badge NFT contract deployed to: ', await badge.getAddress())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});