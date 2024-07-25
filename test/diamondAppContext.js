/* global ethers */

const { getSelectors, FacetCutAction } = require("../scripts/libs/diamond.js")
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")
const { ethers } = require('hardhat')

const NULL_ADDR = "0x0000000000000000000000000000000000000000"

describe('Test Profileio Diamond', function () {

    async function deploy() {

        const accounts = await ethers.getSigners()
        const owner = accounts[0]
        const backupOwner = accounts[1]
        const feeCollector = accounts[2]

        const signer = (await ethers.provider.getSigner(0))

        // Deploy mock USDC token
        const USDC = await ethers.getContractFactory("ERC20Token")
        const usdc = await USDC.deploy(
            "USD Coin",
            "USDC",
            6
        )
        await usdc.waitForDeployment()
        console.log("USDC deployed: ", await usdc.getAddress())

        // Deploy Badge NFT
        const Badge = await ethers.getContractFactory("BadgeV2")
        const badge = await Badge.deploy([
            await owner.getAddress()
        ])
        await badge.waitForDeployment()
        console.log("Badge NFT deployed: ", await badge.getAddress())

        /* Diamond deployment steps */
        // Deploy DiamondCutFacet
        const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet")
        const diamondCutFacet = await DiamondCutFacet.deploy()
        await diamondCutFacet.waitForDeployment()
        console.log("DiamondCutFacet deployed: ", await diamondCutFacet.getAddress())

        // Deploy Diamond
        const Diamond = await ethers.getContractFactory("Diamond")
        const diamond = await Diamond.deploy(
            await owner.getAddress(),
            await diamondCutFacet.getAddress()
        )
        await diamond.waitForDeployment()
        console.log("Diamond deployed: ", await diamond.getAddress())

        // Deploy DiamondInit
        // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
        // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
        const DiamondInit = await ethers.getContractFactory('InitDiamond')
        const diamondInit = await DiamondInit.deploy()
        await diamondInit.waitForDeployment()
        console.log('DiamondInit deployed:', await diamondInit.getAddress())

        // Deploy facets
        const FacetNames = [
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "AccountManagerFacet",
            "BadgeEndorsementFacet",
            "BadgeManagerFacet"
        ]
        const cut = []
        for (const FacetName of FacetNames) {
            const Facet = await ethers.getContractFactory(FacetName)
            const facet = await Facet.deploy()
            await facet.waitForDeployment()
            console.log(`${FacetName} deployed: ${await facet.getAddress()}`)
            cut.push({
                facetAddress: await facet.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(facet)
            })
        }

        const initArgs = [{
            defaultMintPayment: await usdc.getAddress(),
            defaultMintFee: "500000",
            roles: [ // Owner (msg.sender) is set as admin by default.
                await backupOwner.getAddress(),
                await feeCollector.getAddress()
            ]
        }]

        // Upgrade diamond with facets
        console.log('')
        console.log('Diamond Cut:', cut)
        const diamondCut = await ethers.getContractAt('IDiamondCut', await diamond.getAddress())
        let tx
        let receipt
        // Call to init function
        let functionCall = diamondInit.interface.encodeFunctionData('init', initArgs)
        tx = await diamondCut.diamondCut(cut, await diamondInit.getAddress(), functionCall)
        console.log('Diamond cut tx: ', tx.hash)
        receipt = await tx.wait()
        if (!receipt.status) {
            throw Error(`Diamond upgrade failed: ${tx.hash}`)
        }
        console.log('Completed diamond cut')

        // Set Diamond as authorized in Badge NFT contract.
        await badge.setAuthorized(await diamond.getAddress(), 1)

        const profileIo = (await ethers.getContractAt("Profileio", await diamond.getAddress())).connect(signer)

        // Set mint enabled for the Badge in the diamond.
        await profileIo.setMintEnabled(await badge.getAddress(), 1)

        return { owner, usdc, badge, diamond, profileIo, feeCollector }
    }

    it("Should mint badge", async function () {

        const { owner, usdc, badge, profileIo, feeCollector } = await loadFixture(deploy)

        // Mint is executed by Profileio wallet (owner in this case).
        // First test with no payer.
        await profileIo.mint(
            await badge.getAddress(), // badge
            NULL_ADDR, // payer
            await owner.getAddress(), // to
            "profile.io/api/badge/0" // tokenURI
        )
        console.log("Badge minted")

        // Second test with payer.
        await usdc.approve(await profileIo.getAddress(), "500000")

        await profileIo.mint(
            await badge.getAddress(), // badge
            await owner.getAddress(), // payer
            await owner.getAddress(), // to
            "profile.io/api/badge/1" // tokenURI
        )
        console.log("Badge minted")

        console.log("Fee collector balance: ", await usdc.balanceOf(await feeCollector.getAddress()))
    })
})