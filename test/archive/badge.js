/* global ethers */

const { ethers } = require('hardhat')
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")

describe('Soulbound NFT Badge', function() {

    async function deploy() {

        const accounts = await ethers.getSigners()
        const owner = accounts[0]
        const user = accounts[1]
        const userSigner = await ethers.getImpersonatedSigner(await user.getAddress())

        // Deploy payment ERC20.
        const USDC = await ethers.getContractFactory("ERC20Token")
        const usdc = await USDC.deploy(
            "USD Coin",
            "USDC",
            6
        )
        await usdc.waitForDeployment()
        console.log("USDC deployed: ", await usdc.getAddress())

        // Mint 20 USDC to user.
        await usdc.mint(user.getAddress(), 20)
        console.log("Minted USDC to user")

        // Deploy SBNFT Badge contract.
        const Badge = await ethers.getContractFactory("Badge")
        const badge = await Badge.deploy(
            owner.getAddress(),
            await usdc.getAddress(),
            "5000000" // 5 USDC mint fee.
        )
        await badge.waitForDeployment()
        console.log("Badge NFT contract deployed to: ", await badge.getAddress())

        return { owner, usdc, badge, user, userSigner }
    }

    it("Should mint", async function() {

        const { owner, usdc, badge, user, userSigner } = await loadFixture(deploy)

        // User submit spend approval.
        const _usdc = usdc.connect(userSigner)
        await _usdc.approve(badge.getAddress(), await _usdc.balanceOf(await user.getAddress()))
        console.log("Approved Badge contract spend")

        // Mint badge.
        await badge.safeMint(
            await user.getAddress(),
            await user.getAddress(),
            "profile.io/api/badge/1"
        )
        console.log("Badge minted")

        // Check badge owner - tokenId starts at 0.
        console.log("Badge owner: ", await badge.ownerOf(0))

        // Check tokenURI has been set for tokenId
        console.log("Badge tokenURI: ", await badge.tokenURI(0))

        // Check user USDC balance.
        console.log("User USDC bal: ", await _usdc.balanceOf(await user.getAddress()))

        // Check fee collector USDC balance.
        console.log("Fee Collector USDC bal: ", await _usdc.balanceOf(await owner.getAddress()))
    })
})