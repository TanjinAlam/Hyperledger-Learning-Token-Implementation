import { ethers } from "hardhat";

// async function main() {
//   const currentTimestampInSeconds = Math.round(Date.now() / 1000);
//   const unlockTime = currentTimestampInSeconds + 60;

//   const lockedAmount = ethers.utils.parseEther("0.001");

//   const Lock = await ethers.getContractFactory("Lock");
//   const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

//   await lock.deployed();

//   console.log(
//     `Lock with ${ethers.utils.formatEther(lockedAmount)}ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`
//   );
// }

async function main() {
  //     const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  //   const unlockTime = currentTimestampInSeconds + 60;
  const StudentAttendance = await ethers.getContractFactory(
    "StudentAttendance"
  );
  const studentAttendance = await StudentAttendance.deploy();

  await studentAttendance.deployed();

  console.log(
    `StudentAttendance Contract deployed to ${studentAttendance.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
