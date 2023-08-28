import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
describe("StudentHelpingContract", function () {
  let studentHelpingToken: any,
    events: any,
    superadminWallet: any,
    superadminAddress: any,
    institutionWallet: any,
    institutionAddress: any,
    instructor1Wallet: any,
    instructor1Address: any,
    instructor2Wallet: any,
    instructor2Address: any,
    learner1Wallet: any,
    learner1Address: any,
    learner2Wallet: any,
    learner2Address: any,
    randomUserWallet: any,
    randomUserAddress: any,
    learnerAddress: any;
  const institutionName = "MIT";
  const instructorName = "Alfenso";
  const learner1Name = "Piash";
  const learner2Name = "Tanjin";
  const courseName = "CS50";
  const totalSupply = 100;
  const courseId = 0;
  const inistitution1Id = 0;
  const instructor1Id = 0;
  const learner1Id = 0;
  const course1Id = 0;
  const tokenId = 0;
  const fieldOfKnowledge = "Programming";
  const skillName = "Solidity";
  const amount = 1;
  async function intToBytesData(value: any) {
    const encodedValue = ethers.utils.defaultAbiCoder.encode(
      ["uint256"],
      [value]
    );
    return encodedValue;
  }

  before(async () => {
    const accounts = await ethers.getSigners();
    superadminAddress = accounts[0].address;
    institutionWallet = accounts[1];
    institutionAddress = accounts[1].address;
    instructor1Wallet = accounts[2];
    instructor1Address = accounts[2].address;
    learner1Wallet = accounts[3];
    learner1Address = accounts[3].address;
    learner2Wallet = accounts[4];
    learner2Address = accounts[4].address;
    randomUserWallet = accounts[5];
    randomUserAddress = accounts[5].address;
    instructor2Wallet = accounts[6];
    instructor2Address = accounts[6].address;
    learnerAddress = [learner1Address];

    const StudentHelpingToken = await ethers.getContractFactory(
      "StudentHelpingToken"
    );
    studentHelpingToken = await StudentHelpingToken.deploy();
  });
  //checking the first address of the hardhat account is the superadmin of the contract
  it("Contract creator is superadmin", async function () {
    expect(await studentHelpingToken.owner()).to.be.equal(superadminAddress);
  });
  //creating institution from from super admin account function call
  it("Should create institution from superadmin account", async function () {
    const currentTimestamp = Math.floor(Date.now() / 1000);
    await studentHelpingToken.registerInstitution(
      institutionName,
      institutionAddress,
      currentTimestamp
    );
    const event = await studentHelpingToken.queryFilter(
      "InstitutionRegistered"
    );
    expect(event[0].args.institutionId).to.be.equal(0);
    expect(event[0].args.institutionName).to.be.equal(institutionName);
    expect(event[0].args.registeredTime).to.be.equal(currentTimestamp);
  });
  it("Should not allow non-owner to register an institution", async function () {
    const currentTimestamp = Math.floor(Date.now() / 1000);
    try {
      const studentAttendanceContractWithRandomUser =
        await studentHelpingToken.connect(randomUserWallet);
      await expect(
        studentAttendanceContractWithRandomUser.registerInstitution(
          institutionName,
          institutionAddress,
          currentTimestamp
        )
      ).to.be.revertedWith("Ownable: caller is not the owner");
    } catch (error: any) {}
  });
  it("Should register instructor as individual entity", async function () {
    const studentAttendanceContractWithInstructor =
      await studentHelpingToken.connect(instructor1Wallet);
    const currentTimestamp = Math.floor(Date.now() / 1000);
    await studentAttendanceContractWithInstructor.registerInstructor(
      instructorName,
      instructor1Address,
      currentTimestamp
    );
    // console.log(
    //   "HERE+======= outerrrr",
    //   await studentAttendance.instructors(instructorAddress)
    // );
    const event = await studentAttendanceContractWithInstructor.queryFilter(
      "InstructorRegistered"
    );
    expect(event[0].args.instructorId).to.be.equal(0);
    expect(event[0].args.instructorName).to.be.equal(instructorName);
    expect(event[0].args.registeredTime).to.be.equal(currentTimestamp);
  });
  //add instructor under a institution
  it("Should register registered instructor under registered institution", async function () {
    try {
      const InstructorWallet = await studentHelpingToken.connect(
        institutionWallet
      );
      const currentTimestamp = Math.floor(Date.now() / 1000);
      await InstructorWallet.addInstructorToInstitution(
        instructor1Address,
        currentTimestamp
      );
      const event = await InstructorWallet.queryFilter(
        "InstructorRegisteredUnderInstitution"
      );
      expect(event[0].args.instructorId).to.be.equal(0);
      expect(event[0].args.instructorName).to.be.equal(instructorName);
      expect(event[0].args.institutionId).to.be.equal(0);
      expect(event[0].args.institutionName).to.be.equal(institutionName);
      expect(event[0].args.registeredTime).to.be.equal(currentTimestamp);
    } catch (error: any) {
      console.log("ERROR", error);
    }
  });

  it("Should not allow an unregister instructor under an institution", async function () {
    try {
      const studentAttendanceContractWithInstitution =
        await studentHelpingToken.connect(institutionWallet);
      const currentTimestamp = Math.floor(Date.now() / 1000);
      //   await expectRevert(
      //     studentAttendanceContractWithInstitution.addInstructorToInstitution(
      //       randomUserAddress,
      //       currentTimestamp
      //     ),
      //     "Instructor is not registered"
      //   );
      await expect(
        studentAttendanceContractWithInstitution.addInstructorToInstitution(
          randomUserAddress,
          currentTimestamp
        )
      ).to.be.revertedWith("Instructor is not registered");
    } catch (error: any) {
      console.log(error);
    }
  });

  it("Should not allow an unregister institution invoke add instructor to institution", async function () {
    try {
      const studentAttendanceContractWithInstitution =
        await studentHelpingToken.connect(randomUserWallet);
      const currentTimestamp = Math.floor(Date.now() / 1000);
      //   await expectRevert(
      //     studentAttendanceContractWithInstitution.addInstructorToInstitution(
      //       randomUserAddress,
      //       currentTimestamp
      //     ),
      //     "Only institution admin has the permission"
      //   );

      await expect(
        studentAttendanceContractWithInstitution.addInstructorToInstitution(
          randomUserAddress,
          currentTimestamp
        )
      ).to.be.revertedWith("Only institution admin has the permission");
    } catch (error: any) {
      console.log(error);
    }
  });

  it("Should register a learner as individual entity", async function () {
    try {
      const studentAttendanceContractWithLearner =
        await studentHelpingToken.connect(learner1Wallet);
      const currentTimestamp = Math.floor(Date.now() / 1000);
      await studentAttendanceContractWithLearner.registerLearner(
        learner1Address,
        learner1Name,
        currentTimestamp
      );
      const event = await studentAttendanceContractWithLearner.queryFilter(
        "LearnerRegistered"
      );
      expect(event[0].args.learnerId).to.be.equal(0);
      expect(event[0].args.learnerName).to.be.equal(learner1Name);
      expect(event[0].args.registeredTime).to.be.equal(currentTimestamp);
    } catch (error: any) {
      console.log("ERROR", error);
    }
  });
  it("Should create a course by registered instructor under registered institution", async function () {
    try {
      const InstructorWallet = await studentHelpingToken.connect(
        instructor1Wallet
      );
      const currentTimestamp = Math.floor(Date.now() / 1000);
      await InstructorWallet.createCourse(
        institutionAddress,
        courseName,
        currentTimestamp,
        learnerAddress
      );

      const event = await InstructorWallet.queryFilter("CourseCreated");
      expect(event[0].args.courseId).to.be.equal(0);
      expect(event[0].args.instructorId).to.be.equal(0);
      expect(event[0].args.institutionId).to.be.equal(0);
      expect(event[0].args.courseName).to.be.equal(courseName);
    } catch (error: any) {
      console.log("ERROR", error);
    }
  });
  //   //   create a failed transaction of above
  it("Should not add already registered learner to existing course by a valid instructor", async function () {
    try {
      const Learner2Wallet = await studentHelpingToken.connect(learner2Wallet);
      const currentTimestamp = Math.floor(Date.now() / 1000);
      await Learner2Wallet.registerLearner(
        learner2Address,
        learner2Name,
        currentTimestamp
      );
      const InstructorWallet = await studentHelpingToken.connect(
        instructor1Wallet
      );
      await InstructorWallet.addLearnerToCourse(
        courseId,
        learner2Address,
        institutionAddress
      );
      //   await expectRevert(
      //     InstructorWallet.addLearnerToCourse(
      //       courseId,
      //       learner2Address,
      //       institutionAddress
      //     ),
      //     "learner already in the course"
      //   );

      await expect(
        InstructorWallet.addLearnerToCourse(
          courseId,
          learner2Address,
          institutionAddress
        )
      ).to.be.revertedWith("learner already in the course");
    } catch (error: any) {
      console.log("ERROR", error);
    }
  });

  //   //define metadata
  //   it("Should set token metadata from the assigned instructor", async function () {
  //     try {
  //       const InstructorWallet = await studentAttendance.connect(
  //         instructor1Wallet
  //       );
  //       const currentTimestamp = Math.floor(Date.now() / 1000);
  //       await InstructorWallet.setTokenMetadata(
  //         courseId,
  //         inistitution1Id,
  //         instructor1Id,
  //         fieldOfKnowledge,
  //         skillName,
  //         institutionAddress,
  //         currentTimestamp
  //       );
  //       const event = await InstructorWallet.queryFilter("TokenMetadataCreated");
  //       expect(event[0].args.courseId).to.be.equal(course1Id);
  //       expect(event[0].args.courseTokenId).to.be.equal(course1Id);
  //       expect(event[0].args.institutionId).to.be.equal(inistitution1Id);
  //       expect(event[0].args.instructorId).to.be.equal(instructor1Id);
  //       expect(event[0].args.skillName).to.be.equal(skillName);
  //       expect(event[0].args._fieldOfKnowledge).to.be.equal(fieldOfKnowledge);
  //       expect(event[0].args.registeredTime).to.be.equal(currentTimestamp);
  //     } catch (error: any) {
  //       console.log("ERROR", error);
  //     }
  //   });

  //   //transfer token to course learner
  //   it("Should transfer token to course learner", async function () {
  //     try {
  //       const courseId = intToBytesData(course1Id);
  //       const InstructorWallet = await studentAttendance.connect(
  //         instructor1Wallet
  //       );
  //       //   console.log(
  //       //     "HERE====",
  //       //     await studentAttendance.getProgramLearnerDetails(0, learner1Address)
  //       //   );
  //       await InstructorWallet.safeTransferFrom(
  //         instructor1Address,
  //         learner1Address,
  //         course1Id,
  //         amount,
  //         courseId
  //       );
  //       const event = await InstructorWallet.queryFilter(
  //         "AttendanceTokenTransfered"
  //       );
  //       expect(event[0].args.from).to.be.equal(instructor1Address);
  //       expect(event[0].args.to).to.be.equal(learner1Address);
  //       expect(event[0].args.tokenId).to.be.equal(course1Id);
  //       expect(event[0].args.amount).to.be.equal(amount);
  //     } catch (error: any) {
  //       console.log("ERROR", error);
  //     }
  //   });

  //   transfer token to course learner

  // start from here

  it("Should transfer helping token to course learner", async function () {
    try {
      //   const courseId = intToBytesData(course1Id);
      const InstructorWallet = await studentHelpingToken.connect(
        instructor1Wallet
      );
      //   console.log(
      //     "HERE====",
      //     await studentAttendance.getProgramLearnerDetails(0, learner1Address)
      //   );
      const currentTimestamp = Math.floor(Date.now() / 1000);
      await InstructorWallet.mintAttendanceToken(
        0,
        amount,
        courseId,
        currentTimestamp
      );
      const event = await InstructorWallet.queryFilter("HelpingTokenMinted");
      expect(event[0].args.holderAddress).to.be.equal(learner1Address);
      expect(event[0].args.tokenId).to.be.equal(tokenId);
      expect(event[0].args.courseId).to.be.equal(courseId);
      expect(event[0].args.amount).to.be.equal(amount);
    } catch (error: any) {
      console.log("ERROR", error);
    }
  });

  //   //   //transfer token to course learner
  it("Learner should have token", async function () {
    try {
      const learnerBalance = await studentHelpingToken.balanceOf(
        learner1Address,
        tokenId
      );
      console.log("learnerBalance", learnerBalance);
      expect(learnerBalance).to.equal(1);
    } catch (error: any) {
      console.log("ERROR", error);
    }
  });

  //   //   //transfer token to course learner
  it("Should transfer helpint token to anyone", async function () {
    try {
      const courseId = intToBytesData(course1Id);
      const InstructorWallet = await studentHelpingToken.connect(
        learner1Wallet
      );
      await InstructorWallet.safeTransferFrom(
        learner1Address,
        learner2Address,
        tokenId,
        amount,
        courseId
      );
      //   await expectRevert(
      //     InstructorWallet.safeTransferFrom(
      //       learner1Address,
      //       learner2Address,
      //       tokenId,
      //       amount,
      //       courseId
      //     ),
      //     "Instructor not found in the institution"
      //   );

      const event = await InstructorWallet.queryFilter(
        "HelpingTokenTransfered"
      );
      expect(event[0].args.from).to.be.equal(learner1Address);
      expect(event[0].args.to).to.be.equal(learner2Address);
      expect(event[0].args.tokenId).to.be.equal(tokenId);
      expect(event[0].args.amount).to.be.equal(amount);
      //   expect(event[0].args.courseId).to.be.equal(courseId);
      // Event assertions can verify that the arguments are the expected ones
    } catch (error: any) {
      console.log("ERROR", error);
    }
  });

  //   it("Learner should have token", async function () {
  //     try {
  //       const learnerBalance1 = await studentAttendance.balanceOf(
  //         learner1Address,
  //         course1Id
  //       );
  //       console.log("learnerBalance", learnerBalance1);

  //       const learnerBalance2 = await studentAttendance.balanceOf(
  //         learner2Address,
  //         course1Id
  //       );
  //       console.log("learnerBalance", learnerBalance2);
  //       //   expect(learnerBalance).to.equal(1);
  //     } catch (error: any) {
  //       console.log("ERROR", error);
  //     }
  //   });

  //add learnter to course

  //trasnfer token within course learner

  // mint
  // burn

  // revoke access
  // institutiion -> instructor

  //check added learners
  //cehck added instructor
  //check added institution
  //check added course

  //   describe("Should create course with registered institution ,instructor & learners ", async function () {
  //
  //   });

  // learner get register
  // teacher create program
  // teacher failed to create program
  // teacher add student to the program
  // teacher mind token under pogram
  // teacher burn token under program
  // teacher transfer token to all student

  // it("Should create instructor under institution from institution admin account", async function () {
  //   await studentAttendance.addInstructorToInstitution(instructorAddress);
  //   const event = await studentAttendance.queryFilter("InstitutionRegistered");
  //   expect(event[0].args.institutionId).to.be.equal(0);
  //   expect(event[0].args.institutionName).to.be.equal(institutionName);
  // });
});
