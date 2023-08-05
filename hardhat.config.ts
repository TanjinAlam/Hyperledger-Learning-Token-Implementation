// import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";

// const config: HardhatUserConfig = {
//   solidity: "0.8.18",
// };

// export default config;

import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();
const { RPC_URL_BESU, PRIV_KEY_1 }: any = process.env;
const config: HardhatUserConfig = {
  // solidity: "0.8.17",
  networks: {
    localhost: {
      accounts: [PRIV_KEY_1],
      url: "http://localhost:8545",
      chainId: 31337,
      gasPrice: 50000000000,
    },
    // besu: {
    //   url: "",
    //   accounts: [PRIV_KEY_1],
    //   // gasPrice: 80000000, // adjust as necessary
    //   // gas: 124500 // adjust as necessary
    // },
    // mumbai: {
    //   url: POLYGON_RPC_URL,
    //   chainId: 80001,
    //   accounts: [PRIV_KEY_3],
    //   // gasPrice: 80000000, // adjust as necessary
    //   // gas: 124500 // adjust as necessary
    // },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  //   etherscan: {
  //     apiKey: POLYGONSCAN_API_KEY,
  //     constructorArguments: [owners, numConfirmationsRequired],
  //   },
};

export default config;
