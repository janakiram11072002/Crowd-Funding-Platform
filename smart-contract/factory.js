import web3 from "./web3";
import CampaignFactory from "./build/CampaignFactory.json";

const instance = new web3.eth.Contract(
  JSON.parse(CampaignFactory.interface),
  "0xFdAb67Aa428D4233dDE62a144b1b25809DB45D82"
);

export default instance;
