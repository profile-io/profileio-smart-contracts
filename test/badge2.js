/* global ethers */

const { ethers } = require('hardhat')
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")

describe('Soulbound NFT Badge', function() {

    async function deploy() {

        const accounts = await ethers.getSigners()
        const owner = accounts[0]

        const alice = accounts[1]
        const aliceSigner = await ethers.getImpersonatedSigner(await alice.getAddress())

        const bob = accounts[2]
        const bobSigner = await ethers.getImpersonatedSigner(await bob.getAddress())

        const charlie = accounts[3]
        const charlieSigner = await ethers.getImpersonatedSigner(await charlie.getAddress())

        const dave = accounts[4]
        const daveSigner = await ethers.getImpersonatedSigner(await dave.getAddress())

        // Deploy payment ERC20.
        const USDC = await ethers.getContractFactory("ERC20Token")
        const usdc = await USDC.deploy(
            "USD Coin",
            "USDC",
            6
        )
        await usdc.waitForDeployment()
        console.log("USDC deployed: ", await usdc.getAddress())

        // Mint 20 USDC to each user.
        await usdc.mint(await alice.getAddress(), 20)
        await usdc.mint(await bob.getAddress(), 20)
        await usdc.mint(await charlie.getAddress(), 20)
        await usdc.mint(await dave.getAddress(), 20)
        console.log("Minted USDC to users")

        // Deploy Badge Manager contract.
        const BadgeManager = await ethers.getContractFactory("BadgeManager")
        const badgeManager = await BadgeManager.deploy(
            owner.getAddress(),
            await usdc.getAddress(),
            "500000" // 0.5 USDC mint fee.
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

        return { owner, usdc, badge, badgeManager, accounts,
            alice, aliceSigner, bob, bobSigner, charlie, charlieSigner, dave, daveSigner
        }
    }

    it("Should mint", async function() {

        const { owner, usdc, badge, badgeManager, user, userSigner, accounts,
            alice, aliceSigner, bob, bobSigner, charlie, charlieSigner, dave, daveSigner
        } = await loadFixture(deploy)

        // User submit spend approval.
        const aUsdc = usdc.connect(aliceSigner)
        await aUsdc.approve(badgeManager.getAddress(), "20000000")
        console.log("Approved Badge contract spend")

        // Mint badge (from Owner address).
        await badge.safeMint(
            await alice.getAddress(), // to
            await alice.getAddress(), // payer
            "profile.io/api/badge/1" // tokenURI
        )
        console.log("Badge minted")

        // Check badge owner - tokenId starts at 0.
        console.log("Badge owner: ", await badge.ownerOf(0))

        // Check tokenURI has been set for tokenId
        console.log("Badge tokenURI: ", await badge.tokenURI(0))

        // Check user USDC balance.
        console.log("User USDC bal: ", await aUsdc.balanceOf(await alice.getAddress()))

        // Check fee collector USDC balance.
        console.log("Fee Collector USDC bal: ", await aUsdc.balanceOf(await owner.getAddress()))

        // Set custom mint fee of 1 USDC.
        await badgeManager.setMintFee(await badge.getAddress(), "1000000")

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
        console.log("User USDC bal: ", await aUsdc.balanceOf(await alice.getAddress()))

        // Check fee collector USDC balance.
        console.log("Fee Collector USDC bal: ", await aUsdc.balanceOf(await owner.getAddress()))

        // Handle endorsements for tokenId 0.
        const bBadge = badge.connect(bobSigner)
        await bBadge.endorse(0)
        console.log("Badge with tokenId 0 endorsed by: ", await bob.getAddress())

        console.log("Endorsements total: ", await badge.getEndorsementsTotal(0))

        // console.log("getEndorsements: ", await badge.getEndorsements(0))

        const cBadge = badge.connect(charlieSigner)
        await cBadge.endorse(0)
        console.log("Badge with tokenId 0 endorsed by: ", await charlie.getAddress())

        console.log("Endorsements total: ", await badge.getEndorsementsTotal(0))

        // console.log("getEndorsements: ", await badge.getEndorsements(0))

        const dBadge = badge.connect(daveSigner)
        await dBadge.endorse(0)
        console.log("Badge with tokenId 0 endorsed by: ", await dave.getAddress())

        console.log("Endorsements total: ", await badge.getEndorsementsTotal(0))

        await dBadge.revokeEndorsement(0)
        console.log("Badge with tokenId 0 endorsement revoked by: ", await dave.getAddress())

        console.log("Endorsements total: ", await badge.getEndorsementsTotal(0))

        console.log("Endorsements info total: ", await badge.getEndorsementInfoTotal(0))

        // console.log("getEndorsements: ", await badge.getEndorsements(0))

        console.log("get20MostRecentEndorsements: ", await badge.get20Endorsements(
            0, //tokenId
            4, // offset by index
            false // skipRevoked
        ))
    })

    // it("Should show endorsements", async function() {

    //     const { owner, usdc, badge, badgeManager, user, userSigner, dummySigners } = await loadFixture(deploy)

    //     // User submit spend approval.
    //     const _usdc = usdc.connect(userSigner)
    //     await _usdc.approve(badgeManager.getAddress(), "5000000")
    //     console.log("Approved Badge contract spend")

    //     // Mint badge (from Owner address).
    //     await badge.safeMint(
    //         await user.getAddress(), // to
    //         await user.getAddress(), // payer
    //         "profile.io/api/badge/1" // tokenURI
    //     )
    //     console.log("Badge minted")

    //     // Check badge owner - tokenId starts at 0.
    //     console.log("Badge owner: ", await badge.ownerOf(0))

    //     // Endorse badge by 21 other accounts
    //     for (let i = 2; i < 23; i++) {
    //         const dummySigner = dummySigners[i]
    //         const _badge = badge.connect(dummySigner)
    //         await _badge.endorse(0)
    //         console.log("Badge endorsed by: ", await dummySigner.getAddress())
    //     }

    //     // Get endorsements total
    //     console.log("Endorsements total: ", await badge.getEndorsementsTotal(0))
    //     console.log("Endorsements: ", await badge.getEndorsements(0))
    // })
})