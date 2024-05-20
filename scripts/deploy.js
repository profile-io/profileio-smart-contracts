/* global ethers */

const { ethers } = require('hardhat')

async function main() {

    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    // https://amoy.polygonscan.com/address/0xaB7547204a9442AD9d829dA1FB044794816EcdE6#code
    // const ERC20Token = await ethers.getContractFactory('ERC20Token')
    // const erc20Token = await ERC20Token.deploy(
    //     "Test USDC",
    //     "USDC",
    //     6
    // )
    // await erc20Token.waitForDeployment()
    // console.log('Contract deployed to: ', await erc20Token.getAddress())

    // Deploy Badge Manager contract.
    // const BadgeManager = await ethers.getContractFactory("BadgeManager")
    // const badgeManager = await BadgeManager.deploy(
    //     owner.getAddress(),
    //     "0xaB7547204a9442AD9d829dA1FB044794816EcdE6",
    //     "5000000" // 5 USDC mint fee.
    // )
    // await badgeManager.waitForDeployment()
    // console.log("Badge Manager contract deployed to: ", await badgeManager.getAddress())

    // Deploy SBNFT Badge contract.
    const Badge = await ethers.getContractFactory("Badge")
    const badge = await Badge.deploy(
        owner.getAddress(),
        // await badgeManager.getAddress()
        "0xB470EE20D55dBdc44236d9F17bB14e56f622D67c"
    )
    await badge.waitForDeployment()
    console.log("Badge NFT contract deployed to: ", await badge.getAddress())

    // Set Badge in Badge Manager contract.
    await badgeManager.setBadge(await badge.getAddress(), 1)
    console.log("Badge set")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});