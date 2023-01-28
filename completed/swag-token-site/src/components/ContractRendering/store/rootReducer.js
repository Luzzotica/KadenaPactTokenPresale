import { combineReducers } from "redux";
import connectWalletModalSlice from "../../KDAWallet/store/connectWalletModalSlice";
import kadenaSlice from "../../KDAWallet/store/kadenaSlice";
import saleSlice from "./saleSlice";

const rootReducer = combineReducers({
  kadenaInfo: kadenaSlice,
  connectWalletModal: connectWalletModalSlice,
  saleInfo: saleSlice
});

export default rootReducer;