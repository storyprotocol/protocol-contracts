const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

describe("Counter.sol: Unit Test", function () {
    let Counter;
    let counter;
    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        Counter = await ethers.getContractFactory("Counter");
        counter = await Counter.deploy();
        counter.setNumber(0);
    });

    describe("Test Increment", function () {
        it("Increase counter", async function () {
            counter.increment();
        });
    });

    describe("Test Set Number", function () {
        it("Set number", async function () {
            counter.setNumber(2);
        });
    });
});
