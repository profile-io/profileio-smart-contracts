/* global ethers */

const { ethers } = require('hardhat')

async function main() {

    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const ERC20Token = await ethers.getContractFactory('ERC20Token')
    const erc20Token = await ERC20Token.deploy(
        "Test USDC",
        "USDC",
        6
    )
    await erc20Token.waitForDeployment()
    console.log('Contract deployed to: ', await erc20Token.getAddress())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});