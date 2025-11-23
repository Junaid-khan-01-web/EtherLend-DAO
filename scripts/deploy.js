const { ethers } = require("hardhat");

async function main() {
  const EtherLendDAO = await ethers.getContractFactory("EtherLendDAO");
  const etherLendDAO = await EtherLendDAO.deploy();

  await etherLendDAO.deployed();

  console.log("EtherLendDAO contract deployed to:", etherLendDAO.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
