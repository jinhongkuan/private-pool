// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log(deployer);
  const chainId = await getChainId();

  const rinkebyDAI = "0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735";

  const BPTDeployment = await deploy("BlenderTokens", {
    from: deployer,
    log: true,
    waitConfirmations: 2,
  });

  console.log("BPT address: ", BPTDeployment.address);
  const BTNContract = await ethers.getContractAt(
    "BlenderTokens",
    BPTDeployment.address
  );

  const TKNDeployment = await deploy("BlenderTokens", {
    from: deployer,
    log: true,
    waitConfirmations: 2,
  });

  console.log("TKN address: ", TKNDeployment.address);
  const TKNContract = await ethers.getContractAt(
    "BlenderTokens",
    TKNDeployment.address
  );
  console.log(await TKNContract.owner());
  console.log(deployer);
  // const DAIDeployment = await deploy("DAI", {
  //   from: deployer,
  //   log: true,
  //   waitConfirmations: 2,
  // });

  // console.log("DAI address: ", DAIDeployment.address);
  // const DAIContract = await ethers.getContractAt("DAI", DAIDeployment.address);

  const MasterVaultDeployment = await deploy("MasterVault", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [BPTDeployment.address, TKNDeployment.address, rinkebyDAI],
    log: true,
    waitConfirmations: 2,
  });

  await BTNContract.transferOwnership(MasterVaultDeployment.address, {
    from: deployer,
  });
  await TKNContract.transferOwnership(MasterVaultDeployment.address, {
    from: deployer,
  });

  console.log("MasterVault address: ", MasterVaultDeployment.address);

  // const MasterVault = await ethers.getContract("MasterVault", deployer);

  /*  await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // await yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */

  // Verify from the command line by running `yarn verify`

  // You can also Verify your contracts with Etherscan here...
  // You don't want to verify on localhost
  // try {
  //   if (chainId !== localChainId) {
  //     await run("verify:verify", {
  //       address: YourContract.address,
  //       contract: "contracts/YourContract.sol:YourContract",
  //       constructorArguments: [],
  //     });
  //   }
  // } catch (error) {
  //   console.error(error);
  // }
};
module.exports.tags = ["YourContract"];
