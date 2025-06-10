const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CropBatchToken", function () {
    let cropBatchToken;
    let owner, farmer, user, royaltyRecipient;
    let FARMER_ROLE, DEFAULT_ADMIN_ROLE;

    const SAMPLE_IPFS_URI = "ipfs://QmSampleHash123456789";
    const SAMPLE_IPFS_URI_2 = "ipfs://QmSampleHash987654321";
    const INVALID_URI = "https://example.com/metadata.json";
    const ROYALTY_BPS = 250; // 2.5%

    beforeEach(async function () {
        [owner, farmer, user, royaltyRecipient] = await ethers.getSigners();
        const CropBatchToken = await ethers.getContractFactory("CropBatchToken");

        // Deploy the contract, passing owner.address as the defaultAdmin for Ownable
        cropBatchToken = await CropBatchToken.deploy(
            owner.address, // This will be the initialOwner for Ownable and defaultAdmin for AccessControl
            "https://api.greenledger.com/metadata/{id}",
            royaltyRecipient.address,
            ROYALTY_BPS
        );
        await cropBatchToken.deployed();

        FARMER_ROLE = await cropBatchToken.FARMER_ROLE();
        DEFAULT_ADMIN_ROLE = await cropBatchToken.DEFAULT_ADMIN_ROLE();
    });

    describe("Deployment", function () {
        it("Should set the correct admin role", async function () {
            expect(await cropBatchToken.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
        });

        it("Should set the correct farmer role for admin", async function () {
            expect(await cropBatchToken.hasRole(FARMER_ROLE, owner.address)).to.be.true;
        });

        it("Should set the correct royalty info", async function () {
            const royaltyInfo = await cropBatchToken.royaltyInfo(1, 10000);
            expect(royaltyInfo[0]).to.equal(royaltyRecipient.address);
            expect(royaltyInfo[1]).to.equal(ROYALTY_BPS);
        });

        it("Should set the correct owner", async function () {
            expect(await cropBatchToken.owner()).to.equal(owner.address);
        });

        it("Should start with token ID 1", async function () {
            expect(await cropBatchToken.nextTokenId()).to.equal(1);
        });
    });

    describe("Role Management", function () {
        it("Should allow admin to grant farmer role", async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
            expect(await cropBatchToken.hasRole(FARMER_ROLE, farmer.address)).to.be.true;
        });

        it("Should allow admin to revoke farmer role", async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
            await cropBatchToken.revokeFarmerRole(farmer.address);
            expect(await cropBatchToken.hasRole(FARMER_ROLE, farmer.address)).to.be.false;
        });

        it("Should not allow non-admin to grant farmer role", async function () {
            await expect(
                cropBatchToken.connect(user).grantFarmerRole(farmer.address)
            ).to.be.revertedWith("Only admin can grant roles");
        });

        it("Should not allow non-admin to revoke farmer role", async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
            await expect(
                cropBatchToken.connect(user).revokeFarmerRole(farmer.address)
            ).to.be.revertedWith("Only admin can revoke roles");
        });

        it("Should allow users to renounce non-admin roles", async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
            await cropBatchToken.connect(farmer).renounceRole(FARMER_ROLE, farmer.address);
            expect(await cropBatchToken.hasRole(FARMER_ROLE, farmer.address)).to.be.false;
        });

        it("Should not allow renouncing admin role", async function () {
            await expect(
                cropBatchToken.connect(owner).renounceRole(DEFAULT_ADMIN_ROLE, owner.address)
            ).to.be.revertedWith("Cannot renounce admin role");
        });

        it("Should not allow renouncing roles for others", async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
            await expect(
                cropBatchToken.connect(user).renounceRole(FARMER_ROLE, farmer.address)
            ).to.be.revertedWith("Can only renounce roles for self");
        });
    });

    describe("Minting", function () {
        beforeEach(async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
        });

        it("Should allow farmer to mint a token", async function () {
            await expect(
                cropBatchToken.connect(farmer).mint(SAMPLE_IPFS_URI, "0x")
            ).to.emit(cropBatchToken, "CropBatchMinted")
                .withArgs(1, farmer.address, SAMPLE_IPFS_URI);

            expect(await cropBatchToken.balanceOf(farmer.address, 1)).to.equal(1);
            expect(await cropBatchToken.uri(1)).to.equal(SAMPLE_IPFS_URI);
            expect(await cropBatchToken.exists(1)).to.be.true;
            expect(await cropBatchToken.nextTokenId()).to.equal(2);
        });

        it("Should not allow non-farmer to mint", async function () {
            await expect(
                cropBatchToken.connect(user).mint(SAMPLE_IPFS_URI, "0x")
            ).to.be.revertedWith("Caller must be a farmer");
        });

        it("Should not allow empty metadata URI", async function () {
            await expect(
                cropBatchToken.connect(farmer).mint("", "0x")
            ).to.be.revertedWith("Metadata URI cannot be empty");
        });

        it("Should not allow non-IPFS URI", async function () {
            await expect(
                cropBatchToken.connect(farmer).mint(INVALID_URI, "0x")
            ).to.be.revertedWith("URI must start with 'ipfs://'");
        });

        it("Should increment token IDs correctly", async function () {
            await cropBatchToken.connect(farmer).mint(SAMPLE_IPFS_URI, "0x");
            await cropBatchToken.connect(farmer).mint(SAMPLE_IPFS_URI_2, "0x");

            expect(await cropBatchToken.nextTokenId()).to.equal(3);
            expect(await cropBatchToken.exists(1)).to.be.true;
            expect(await cropBatchToken.exists(2)).to.be.true;
            expect(await cropBatchToken.exists(3)).to.be.false;
        });
    });

    describe("Batch Minting", function () {
        beforeEach(async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
        });

        it("Should allow farmer to batch mint tokens", async function () {
            const uris = [SAMPLE_IPFS_URI, SAMPLE_IPFS_URI_2];

            await expect(
                cropBatchToken.connect(farmer).batchMint(uris, "0x")
            ).to.emit(cropBatchToken, "CropBatchMinted")
                .withArgs(1, farmer.address, SAMPLE_IPFS_URI)
                .and.to.emit(cropBatchToken, "CropBatchMinted")
                .withArgs(2, farmer.address, SAMPLE_IPFS_URI_2);

            expect(await cropBatchToken.balanceOf(farmer.address, 1)).to.equal(1);
            expect(await cropBatchToken.balanceOf(farmer.address, 2)).to.equal(1);
            expect(await cropBatchToken.nextTokenId()).to.equal(3);
        });

        it("Should not allow empty batch", async function () {
            await expect(
                cropBatchToken.connect(farmer).batchMint([], "0x")
            ).to.be.revertedWith("No metadata URIs provided");
        });

        it("Should not allow batch size exceeding limit", async function () {
            const uris = new Array(101).fill(SAMPLE_IPFS_URI);
            await expect(
                cropBatchToken.connect(farmer).batchMint(uris, "0x")
            ).to.be.revertedWith("Batch size exceeds limit");
        });

        it("Should not allow non-farmer to batch mint", async function () {
            await expect(
                cropBatchToken.connect(user).batchMint([SAMPLE_IPFS_URI], "0x")
            ).to.be.revertedWith("Caller must be a farmer");
        });
    });

    describe("Metadata Management", function () {
        beforeEach(async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
            await cropBatchToken.connect(farmer).mint(SAMPLE_IPFS_URI, "0x");
        });

        it("Should allow admin to update token URI", async function () {
            await expect(
                cropBatchToken.updateTokenUri(1, SAMPLE_IPFS_URI_2)
            ).to.emit(cropBatchToken, "MetadataUpdated")
                .withArgs(1, SAMPLE_IPFS_URI_2);

            expect(await cropBatchToken.uri(1)).to.equal(SAMPLE_IPFS_URI_2);
        });

        it("Should not allow non-admin to update token URI", async function () {
            await expect(
                cropBatchToken.connect(user).updateTokenUri(1, SAMPLE_IPFS_URI_2)
            ).to.be.revertedWith("Only admin can update URI");
        });

        it("Should not allow updating non-existent token", async function () {
            await expect(
                cropBatchToken.updateTokenUri(999, SAMPLE_IPFS_URI_2)
            ).to.be.revertedWith("Token does not exist");
        });

        it("Should allow admin to freeze metadata", async function () {
            await expect(
                cropBatchToken.freezeMetadata(1)
            ).to.emit(cropBatchToken, "MetadataFrozen")
                .withArgs(1);

            expect(await cropBatchToken.isMetadataFrozen(1)).to.be.true;
        });

        it("Should not allow updating frozen metadata", async function () {
            await cropBatchToken.freezeMetadata(1);
            await expect(
                cropBatchToken.updateTokenUri(1, SAMPLE_IPFS_URI_2)
            ).to.be.revertedWith("Metadata is frozen");
        });

        it("Should not allow non-admin to freeze metadata", async function () {
            await expect(
                cropBatchToken.connect(user).freezeMetadata(1)
            ).to.be.revertedWith("Only admin can freeze metadata");
        });

        it("Should not allow freezing already frozen metadata", async function () {
            await cropBatchToken.freezeMetadata(1);
            await expect(
                cropBatchToken.freezeMetadata(1)
            ).to.be.revertedWith("Metadata already frozen");
        });
    });

    describe("Token Queries", function () {
        beforeEach(async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
            await cropBatchToken.connect(farmer).mint(SAMPLE_IPFS_URI, "0x");
        });

        it("Should return correct token URI", async function () {
            expect(await cropBatchToken.uri(1)).to.equal(SAMPLE_IPFS_URI);
        });

        it("Should revert for non-existent token URI", async function () {
            await expect(
                cropBatchToken.uri(999)
            ).to.be.revertedWith("Token does not exist");
        });

        it("Should return correct existence status", async function () {
            expect(await cropBatchToken.exists(1)).to.be.true;
            expect(await cropBatchToken.exists(0)).to.be.false;
            expect(await cropBatchToken.exists(999)).to.be.false;
        });

        it("Should return correct next token ID", async function () {
            expect(await cropBatchToken.nextTokenId()).to.equal(2);
            await cropBatchToken.connect(farmer).mint(SAMPLE_IPFS_URI_2, "0x");
            expect(await cropBatchToken.nextTokenId()).to.equal(3);
        });
    });

    describe("ERC165 Support", function () {
        it("Should support ERC1155 interface", async function () {
            expect(await cropBatchToken.supportsInterface("0xd9b67a26")).to.be.true;
        });

        it("Should support AccessControl interface", async function () {
            expect(await cropBatchToken.supportsInterface("0x7965db0b")).to.be.true;
        });

        it("Should support ERC2981 interface", async function () {
            expect(await cropBatchToken.supportsInterface("0x2a55205a")).to.be.true;
        });

        it("Should support ERC165 interface", async function () {
            expect(await cropBatchToken.supportsInterface("0x01ffc9a7")).to.be.true;
        });
    });

    describe("Royalty Info", function () {
        it("Should return correct royalty info", async function () {
            const salePrice = ethers.utils.parseEther("1");
            const royaltyInfo = await cropBatchToken.royaltyInfo(1, salePrice);

            expect(royaltyInfo[0]).to.equal(royaltyRecipient.address);
            expect(royaltyInfo[1]).to.equal(salePrice.mul(ROYALTY_BPS).div(10000));
        });
    });

    describe("IPFS Validation", function () {
        beforeEach(async function () {
            await cropBatchToken.grantFarmerRole(farmer.address);
        });

        it("Should accept valid IPFS URIs", async function () {
            const validUris = [
                "ipfs://QmSampleHash123456789",
                "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi"
            ];

            for (const uri of validUris) {
                await expect(
                    cropBatchToken.connect(farmer).mint(uri, "0x")
                ).to.not.be.reverted;
            }
        });

        it("Should reject invalid URIs", async function () {
            const invalidUris = [
                "https://example.com/metadata.json",
                "http://example.com/metadata.json",
                "ftp://example.com/metadata.json",
                "ipfs:/",
                "ipfs://",
                "ipfs",
                ""
            ];

            for (const uri of invalidUris) {
                await expect(
                    cropBatchToken.connect(farmer).mint(uri, "0x")
                ).to.be.reverted;
            }
        });
    });
});
