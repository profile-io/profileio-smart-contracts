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

        // Deploy Badge Manager contract.
        const BadgeManager = await ethers.getContractFactory("BadgeManager")
        const badgeManager = await BadgeManager.deploy(
            owner.getAddress(),
            await usdc.getAddress(),
            "5000000" // 5 USDC mint fee.
        )
        await badgeManager.waitForDeployment()
        console.log("Badge Manager contract deployed to: ", await badgeManager.getAddress())

        // Deploy SBNFT Badge contract.
        const Badge = await ethers.getContractFactory("Badge")
        const badge = await Badge.deploy(
            owner.getAddress(),
            await badgeManager.getAddress()
        )
        await badge.waitForDeployment()
        console.log("Badge NFT contract deployed to: ", await badge.getAddress())

        // Set Badge in Badge Manager contract.
        await badgeManager.setBadge(await badge.getAddress(), 1)
        console.log("Badge set")

        return { owner, usdc, badge, badgeManager, user, userSigner }
    }

    it("Should mint", async function() {

        const { owner, usdc, badge, badgeManager, user, userSigner } = await loadFixture(deploy)

        // User submit spend approval.
        const _usdc = usdc.connect(userSigner)
        await _usdc.approve(badgeManager.getAddress(), "5000000")
        console.log("Approved Badge contract spend")

        // Mint badge (from Owner address).
        await badge.safeMint(
            await user.getAddress(), // to
            await user.getAddress(), // payer
            "profile.io/api/badge/1" // tokenURI
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

        // // Set custom mint fee of 10 USDC.
        // await badgeManager.setMintFee(await badge.getAddress(), "10000000")

        // await _usdc.approve(badgeManager.getAddress(), "10000000")
        // console.log("Approved Badge contract spend")

        // Mint badge (from Owner address).
        await badge.safeMint(
            await owner.getAddress(), // to - test minting to a different account.
            "0x0000000000000000000000000000000000000000", // payer - test subsidised mint.
            "profile.io/api/badge/2" // tokenURI
        )
        console.log("Badge minted")

        // Check badge owner - tokenId starts at 0.
        console.log("Badge owner: ", await badge.ownerOf(1))

        // Check tokenURI has been set for tokenId
        console.log("Badge tokenURI: ", await badge.tokenURI(1))

        // Check user USDC balance.
        console.log("User USDC bal: ", await _usdc.balanceOf(await user.getAddress()))

        // Check fee collector USDC balance.
        console.log("Fee Collector USDC bal: ", await _usdc.balanceOf(await owner.getAddress()))
    })
})