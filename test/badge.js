/* global ethers */

const { ethers } = require('hardhat')
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")

describe('Soulbound NFT Badge', function() {

    async function deploy() {

        const accounts = await ethers.getSigners()
        const owner = accounts[0]
        const recipient = accounts[1]

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

        return { owner, recipient, badge }
    }

    it("Should mint", async function() {

        const { owner, recipient, badge } = await loadFixture(deploy)

        await badge.mint()
        console.log("Badge minted")

        // await badge.transfer(recipient.getAddress())
    })

})