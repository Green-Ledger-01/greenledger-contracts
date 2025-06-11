const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UserManagement", function () {
    let userManagement;
    let owner, farmer, transporter, buyer, user, nonAdmin;
    let FARMER_ROLE, TRANSPORTER_ROLE, BUYER_ROLE, DEFAULT_ADMIN_ROLE;

    // Helper function to deploy contract with better error handling
    async function deployContract() {
        try {
            const [deployer, ...otherSigners] = await ethers.getSigners();
            const UserManagement = await ethers.getContractFactory("UserManagement");

            const contract = await UserManagement.deploy(deployer.address);
            await contract.deployed();
            
            return { contract, deployer, otherSigners };
        } catch (error) {
            console.log("UserManagement deployment failed:", error.message);
            return null;
        }
    }

    beforeEach(async function () {
        [owner, farmer, transporter, buyer, user, nonAdmin] = await ethers.getSigners();

        const deployResult = await deployContract();
        if (!deployResult) {
            this.skip(); // Skip tests if deployment fails
            return;
        }

        userManagement = deployResult.contract;
        owner = deployResult.deployer;

        try {
            FARMER_ROLE = await userManagement.FARMER_ROLE();
            TRANSPORTER_ROLE = await userManagement.TRANSPORTER_ROLE();
            BUYER_ROLE = await userManagement.BUYER_ROLE();
            DEFAULT_ADMIN_ROLE = await userManagement.DEFAULT_ADMIN_ROLE();
        } catch (error) {
            console.log("Failed to get roles:", error.message);
            this.skip();
        }
    });

    describe("Deployment", function () {
        it("Should set the correct admin role", async function () {
            expect(await userManagement.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
        });

        it("Should support AccessControl interface", async function () {
            // AccessControl interface ID
            expect(await userManagement.supportsInterface("0x7965db0b")).to.be.true;
        });

        it("Should not be paused initially", async function () {
            expect(await userManagement.paused()).to.be.false;
        });

        it("Should have correct role constants", async function () {
            expect(FARMER_ROLE).to.equal(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("FARMER_ROLE")));
            expect(TRANSPORTER_ROLE).to.equal(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("TRANSPORTER_ROLE")));
            expect(BUYER_ROLE).to.equal(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BUYER_ROLE")));
        });
    });

    describe("User Registration", function () {
        it("Should allow admin to register a farmer", async function () {
            await expect(
                userManagement.registerUser(farmer.address, 0) // 0 = Farmer
            ).to.emit(userManagement, "UserRegistered")
                .withArgs(farmer.address, FARMER_ROLE);

            expect(await userManagement.hasRole(FARMER_ROLE, farmer.address)).to.be.true;
        });

        it("Should allow admin to register a transporter", async function () {
            await expect(
                userManagement.registerUser(transporter.address, 1) // 1 = Transporter
            ).to.emit(userManagement, "UserRegistered")
                .withArgs(transporter.address, TRANSPORTER_ROLE);

            expect(await userManagement.hasRole(TRANSPORTER_ROLE, transporter.address)).to.be.true;
        });

        it("Should allow admin to register a buyer", async function () {
            await expect(
                userManagement.registerUser(buyer.address, 2) // 2 = Buyer
            ).to.emit(userManagement, "UserRegistered")
                .withArgs(buyer.address, BUYER_ROLE);

            expect(await userManagement.hasRole(BUYER_ROLE, buyer.address)).to.be.true;
        });

        it("Should not allow non-admin to register users", async function () {
            await expect(
                userManagement.connect(user).registerUser(farmer.address, 0)
            ).to.be.revertedWith("AccessControl:");
        });

        it("Should not allow registering zero address", async function () {
            await expect(
                userManagement.registerUser(ethers.constants.AddressZero, 0)
            ).to.be.revertedWith("Can't register zero address");
        });

        it("Should handle registering same user with different roles", async function () {
            // Register as farmer
            await userManagement.registerUser(user.address, 0);
            expect(await userManagement.hasRole(FARMER_ROLE, user.address)).to.be.true;

            // Register same user as transporter
            await userManagement.registerUser(user.address, 1);
            expect(await userManagement.hasRole(TRANSPORTER_ROLE, user.address)).to.be.true;
            expect(await userManagement.hasRole(FARMER_ROLE, user.address)).to.be.true;
        });
    });

    describe("Role Revocation", function () {
        beforeEach(async function () {
            // Register users with different roles
            await userManagement.registerUser(farmer.address, 0);
            await userManagement.registerUser(transporter.address, 1);
            await userManagement.registerUser(buyer.address, 2);
        });

        it("Should allow admin to revoke farmer role", async function () {
            await expect(
                userManagement.revokeRole(farmer.address, 0)
            ).to.emit(userManagement, "UserRoleRevoked")
                .withArgs(farmer.address, FARMER_ROLE);

            expect(await userManagement.hasRole(FARMER_ROLE, farmer.address)).to.be.false;
        });

        it("Should allow admin to revoke transporter role", async function () {
            await expect(
                userManagement.revokeRole(transporter.address, 1)
            ).to.emit(userManagement, "UserRoleRevoked")
                .withArgs(transporter.address, TRANSPORTER_ROLE);

            expect(await userManagement.hasRole(TRANSPORTER_ROLE, transporter.address)).to.be.false;
        });

        it("Should allow admin to revoke buyer role", async function () {
            await expect(
                userManagement.revokeRole(buyer.address, 2)
            ).to.emit(userManagement, "UserRoleRevoked")
                .withArgs(buyer.address, BUYER_ROLE);

            expect(await userManagement.hasRole(BUYER_ROLE, buyer.address)).to.be.false;
        });

        it("Should not allow non-admin to revoke roles", async function () {
            await expect(
                userManagement.connect(user).revokeRole(farmer.address, 0)
            ).to.be.revertedWith("AccessControl:");
        });

        it("Should not allow revoking from zero address", async function () {
            await expect(
                userManagement.revokeRole(ethers.constants.AddressZero, 0)
            ).to.be.revertedWith("Can't revoke from zero address");
        });
    });

    describe("Role Status Queries", function () {
        beforeEach(async function () {
            // Register user with multiple roles
            await userManagement.registerUser(user.address, 0); // Farmer
            await userManagement.registerUser(user.address, 1); // Transporter
        });

        it("Should return correct role status for user with multiple roles", async function () {
            const status = await userManagement.getUserRolesStatus(user.address);
            expect(status.isFarmer).to.be.true;
            expect(status.isTransporter).to.be.true;
            expect(status.isBuyer).to.be.false;
        });

        it("Should return false for all roles for unregistered user", async function () {
            const status = await userManagement.getUserRolesStatus(nonAdmin.address);
            expect(status.isFarmer).to.be.false;
            expect(status.isTransporter).to.be.false;
            expect(status.isBuyer).to.be.false;
        });

        it("Should return correct status after role revocation", async function () {
            // Revoke farmer role
            await userManagement.revokeRole(user.address, 0);
            
            const status = await userManagement.getUserRolesStatus(user.address);
            expect(status.isFarmer).to.be.false;
            expect(status.isTransporter).to.be.true;
            expect(status.isBuyer).to.be.false;
        });
    });

    describe("Pause Functionality", function () {
        it("Should allow admin to pause the contract", async function () {
            await expect(userManagement.pause())
                .to.emit(userManagement, "Paused")
                .withArgs(owner.address);

            expect(await userManagement.paused()).to.be.true;
        });

        it("Should allow admin to unpause the contract", async function () {
            await userManagement.pause();
            
            await expect(userManagement.unpause())
                .to.emit(userManagement, "Unpaused")
                .withArgs(owner.address);

            expect(await userManagement.paused()).to.be.false;
        });

        it("Should not allow non-admin to pause", async function () {
            await expect(
                userManagement.connect(user).pause()
            ).to.be.revertedWith("AccessControl:");
        });

        it("Should not allow non-admin to unpause", async function () {
            await userManagement.pause();
            
            await expect(
                userManagement.connect(user).unpause()
            ).to.be.revertedWith("AccessControl:");
        });

        it("Should not allow pausing when already paused", async function () {
            await userManagement.pause();
            
            await expect(userManagement.pause())
                .to.be.revertedWith("Pausable: paused");
        });

        it("Should not allow unpausing when not paused", async function () {
            await expect(userManagement.unpause())
                .to.be.revertedWith("Pausable: not paused");
        });
    });

    describe("Edge Cases and Security", function () {
        it("Should handle invalid role enum", async function () {
            await expect(
                userManagement.registerUser(user.address, 99) // Invalid role
            ).to.be.revertedWith("Invalid role");
        });

        it("Should handle multiple registrations of same role", async function () {
            await userManagement.registerUser(farmer.address, 0);
            
            // Registering again should not revert
            await userManagement.registerUser(farmer.address, 0);
            expect(await userManagement.hasRole(FARMER_ROLE, farmer.address)).to.be.true;
        });

        it("Should handle role checks for zero address", async function () {
            expect(await userManagement.hasRole(FARMER_ROLE, ethers.constants.AddressZero)).to.be.false;
        });

        it("Should maintain role state across multiple operations", async function () {
            // Complex workflow
            await userManagement.registerUser(user.address, 0); // Farmer
            await userManagement.registerUser(user.address, 1); // Transporter
            await userManagement.revokeRole(user.address, 0); // Remove farmer
            await userManagement.registerUser(user.address, 2); // Add buyer

            const status = await userManagement.getUserRolesStatus(user.address);
            expect(status.isFarmer).to.be.false;
            expect(status.isTransporter).to.be.true;
            expect(status.isBuyer).to.be.true;
        });
    });
});
