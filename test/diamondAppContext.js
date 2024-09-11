/* global ethers */

const { getSelectors, FacetCutAction } = require("../scripts/libs/diamond.js")
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")
const { ethers } = require('hardhat')
const { expect } = require("chai");

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

        /* Use Badge Factory instead */
        // // Deploy Badge NFT
        // const Badge = await ethers.getContractFactory("BadgeV2")
        // const badge = await Badge.deploy([
        //     await owner.getAddress()
        // ])
        // await badge.waitForDeployment()
        // console.log("Badge NFT deployed: ", await badge.getAddress())

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
            "DiamondLoupeFacet", // core diamond
            "OwnershipFacet", // core diamond
            "AccountManagerFacet", // application specific
            "BadgeEndorsementFacet", // application specific
            "BadgeManagerFacet" // application specific
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

        return { owner, usdc, badge, diamond, profileIo, feeCollector, backupOwner }
    }

    it("Should mint + endorse badge", async function () {

        const { owner, usdc, badge, profileIo, feeCollector, backupOwner } = await loadFixture(deploy)

        // Mint is executed by Profileio wallet (owner in this case).
        // Note that it is the BE's responsibility to ensure that the account submitting the request has mint permissions.
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

        const profileIo2 = (await ethers.getContractAt("Profileio", await profileIo.getAddress())).connect(backupOwner)

        // Endorse badge
        await profileIo2.endorse(
            await badge.getAddress(), // badge
            1 // tokenId
        )
        console.log("Badge (tokenId: 1) endorsed")

        console.log("Total endorsements: ", await profileIo2.getEndorsementsTotal(await badge.getAddress(), 1))

        console.log("Total endorsements: ", await profileIo2.getEndorsementsTotal(await badge.getAddress(), 1))
        console.log("Total endorsements info: ", await profileIo2.getEndorsementInfoTotal(await badge.getAddress(), 1))

        // TODO: move endorsement test out of mint test
        /**
         * When there are endorsers
         */
        const endorserList = await profileIo2.get20Endorsements(await badge.getAddress(), 1, 0, false);

        expect(endorserList[0][2]).to.equal(1, 'endorserList[0][2] is the first items EndorsementStatus and it should be 1 which means "Endorsed"')

        // Revoking Endorse badge
        await profileIo2.revokeEndorsement(
            await badge.getAddress(), // badge
            1 // tokenId
        )

        const endorserListWithRevokedItem = await profileIo2.get20Endorsements(await badge.getAddress(), 1, 0, false);
        expect(endorserListWithRevokedItem[0][2]).to.equal(2, 'endorserList[0][2] is the first items EndorsementStatus and it should be 1 which means "Revoked"')

        /**
         * In case badge address is a wrong one
         */
        const randomContactAddress = '0x3263B824E20faab50De043c68C14C107a3ee272a';  // random address for test
        const emptyEndorserList = await profileIo2.get20Endorsements(randomContactAddress, 1, 0, false);

        expect(emptyEndorserList.length === 20, "it has to be 20 items");

        const isAllEmptyAddress = emptyEndorserList.every(item => item[1] === NULL_ADDR);

        expect(isAllEmptyAddress === true, 'since the badge contract is the wrong one, returned address should be all empty address');
        
        for(const list of emptyEndorserList ) {
            expect(list[0]).to.equal(0, 'list[0] is timestamp and since the badge contract is the wrong one, it has to be 0');
            expect(list[2]).to.equal(0, 'list[2] is "EndorsementStatus" and since the badge contract is the wrong one, it has to be 0 which is "NotSet"');
        }
    })

    it('should set mint params', async () => {
        const { badge, profileIo } = await loadFixture(deploy)
        const randomContactAddress = '0x3263B824E20faab50De043c68C14C107a3ee272a';  // random address for test
        const badgeAddress = await badge.getAddress();

        await profileIo.setCustomMintParams(
            badgeAddress, // badge
            42, // mintFee
            randomContactAddress, // mintPayment
            1, // enabled
        )

        const params = await profileIo.getMintParams(badgeAddress);
        const [mintPaymentAddress, mintFee] = params;

        expect(mintPaymentAddress).to.equal(randomContactAddress);
        expect(mintFee).to.equal(42);
    })
})