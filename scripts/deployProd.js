/* global ethers */

const { getSelectors, FacetCutAction } = require("../scripts/libs/diamond.js")
const { ethers } = require('hardhat')

const USDC = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"

async function main() {

    const accounts = await ethers.getSigners()
    const owner = accounts[0]
    const backupOwner = "0x3371187a386866dd4bf373D7BFcE0cC734AAB780" // taehwa
    const feeCollector = accounts[0]

    const signer = (await ethers.provider.getSigner(0))

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
        defaultMintPayment: USDC,
        defaultMintFee: "500000",
        roles: [ // Owner (msg.sender) is set as admin by default.
            backupOwner,
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

    // Deploy Badge Factory
    const BadgeFactory = await ethers.getContractFactory("BadgeV2Factory")
    const badgeFactory = await BadgeFactory.deploy(
        await owner.getAddress(),
        await diamond.getAddress()
    )
    await badgeFactory.waitForDeployment()
    console.log("Badge Factory deployed: ", await badgeFactory.getAddress())

    // Create Badge NFT Contract
    await badgeFactory.createBadge();
    const badgeAddr = await badgeFactory.badgeArray(0);
    console.log("Badge contract created at: ", badgeAddr);

    const badge = (await ethers.getContractAt("BadgeV2", badgeAddr)).connect(signer)

    // Set Diamond as authorized in Badge NFT contract.
    await badge.setAuthorized(await diamond.getAddress(), 1)

    const profileIo = (await ethers.getContractAt("Profileio", await diamond.getAddress())).connect(signer)

    // Set mint and endorsement enabled for the Badge in the diamond.
    await profileIo.setMintEnabled(await badge.getAddress(), 1)
    await profileIo.setEndorsementEnabled(await badge.getAddress(), 1)

    console.log('Profile.io:: Deployment finished.');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});