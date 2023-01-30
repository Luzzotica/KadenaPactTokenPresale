import { createSlice } from '@reduxjs/toolkit'
import { local, localAndSend, signAndSend } from '../../KDAWallet/store/kadenaSlice';
import { createCap } from '../../KDAWallet/utils/utils';
import { PRECISION } from '../utils/constants';
import { getCurrentTier } from './saleSliceHelpers';

export const saleSlice = createSlice({
  name: 'saleInfo',
  initialState: {
    contract: import.meta.env.VITE_CONTRACT,
    saleName: import.meta.env.VITE_SALE_NAME,
    bank: '',
    saleData: {},
    totalSupply: 0.0,
    totalSold: 0.0,
    currentTier: {},
    whitelistInfo: {},
    reservation: {},
  },
  reducers: {
    setSaleData: (state, action) => {
      state.saleData = action.payload;
    },
    setTotalSupply: (state, action) => {
      state.totalSupply = action.payload;
    },
    setTotalSold: (state, action) => {
      state.totalSold = action.payload;
    },
    setCurrentTier: (state, action) => {
      state.currentTier = action.payload;
    },
    setWhitelistInfo: (state, action) => {
      state.whitelistInfo = action.payload;
    },
    setBank: (state, action) => {
      state.bank = action.payload;
    },
    setReservation: (state, action) => {
      state.reservation = action.payload;
    }
  },
})

export const { 
  setSaleData, 
  setTotalSupply,
  setTotalSold,
  setCurrentTier, 
  setWhitelistInfo,
  setBank,
  setReservation,
} = saleSlice.actions;

export default saleSlice.reducer;

export const initContractData = (chainId) => {
  return async function(dispatch, getState) {
    
    let contract = getState().saleInfo.contract;
    let saleName = getState().saleInfo.saleName;
    // Get the available free and discount for the user
    var pactCode = `
      (${contract}.get-sale "${saleName}")
    `
    // console.log(pactCode);
    var result = await dispatch(local(chainId, pactCode, {}, [], 150000, 1e-8, true));
    // console.log(result);

    if (result.result.status = 'success') {
      let sale = result.result.data;
      dispatch(saleSlice.actions.setSaleData(sale));
      dispatch(saleSlice.actions.setTotalSupply(sale['total-supply']));
      dispatch(saleSlice.actions.setTotalSold(sale['total-sold']));
      dispatch(saleSlice.actions.setCurrentTier(getCurrentTier(sale.tiers)));
      dispatch(saleSlice.actions.setBank(sale['fungible-bank-account']));
    }
    else {
      toast.error(`Failed to load contract data, error: ${result.message}.`);
    }
  }
}

export const initAccountData = (chainId, account) => {
  return async function(dispatch, getState) {
    let contract = getState().saleInfo.contract;
    let sale = getState().saleInfo.saleName;

    // Get the bods and items for the account
    var pactCode = `
    [
      (${contract}.get-reservation-for-account "${sale}" "${account}")
      {
    `
    // Get the whitelist mint count for each tier that is a WL
    let tiers = getState().saleInfo.saleData.tiers;
    var wlTierCount = 0;
    // console.log(tiers);
    for (var i = 0; i < tiers.length; i++) {

      if (tiers[i]['tier-type'] === 'WL') {
        if (wlTierCount > 0) {
          pactCode += ',';
        }
        pactCode += `
          "${tiers[i]['tier-id']}": (${contract}.get-whitelist-purchase-amount "${sale}" "${tiers[i]['tier-id']}" "${account}")
        `
        wlTierCount++;
      }
    }
    pactCode += '}]'
    // console.log(pactCode);

    var result = await dispatch(local(chainId, pactCode, {}, [], 150000, 1e-8, true));
    // console.log(result);

    if (result.result.status = 'success') {
      // console.log(result.result.data);
      let reservation = result.result.data[0];
      dispatch(saleSlice.actions.setReservation(reservation));

      let whitelistData = result.result.data[1];
      dispatch(saleSlice.actions.setWhitelistInfo(whitelistData));
    }
    else {
      toast.error(`Failed to load user data, error: ${result.message}.`);
      return;
    }
  }
}

export const reserveTokens = (chainId, account, amount) => {
  return async function(dispatch, getState) {
    let contract = getState().saleInfo.contract;
    let totalSold = getState().saleInfo.totalSold;
    let saleName = getState().saleInfo.saleName;
    let bank = getState().saleInfo.bank;

    // Get the bods and items for the account
    var pactCode = `(${contract}.reserve "${saleName}" "${account}" ${amount.toFixed(PRECISION)})`;
    var caps = [
      createCap("Gas", "Allows paying for gas", "coin.GAS", []),
      createCap("Reserve", "Allows reserving tokens", `${contract}.RESERVE`, []),
      createCap("Transfer", "Allows sending KDA to the specified address", "coin.TRANSFER", [account, bank, amount])
    ]
    // var result = await dispatch(local(chainId, pactCode, {}, caps, 2000 * amount, 1e-8, false, true));
    var result = await dispatch(localAndSend(chainId, 
      pactCode, 
      {}, 
      caps, 
      2000, 
      1e-8));
    // console.log('Normal', result);
    
    if (result.result.status === 'success') {
      let currentTier = getState().saleInfo.currentTier;
      let tokenPerFungible = currentTier['token-per-fungible'];
      // console.log('New total sold built from:', totalSold, amount, tokenPerFungible);
      dispatch(saleSlice.actions.setTotalSold(totalSold + amount * tokenPerFungible));

      // Update the reservation to the new amount purchased
      let reservation = getState().saleInfo.reservation;
      let copiedReservation = JSON.parse(JSON.stringify(reservation));
      copiedReservation['amount-token'] += amount * tokenPerFungible;
      dispatch(saleSlice.actions.setReservation(copiedReservation));

      let whitelistInfo = getState().saleInfo.whitelistInfo;
      // If the whitelist info contains the current tier's tier id, 
      // increment the count
      if (whitelistInfo[currentTier['tier-id']]) {
        let info = JSON.parse(JSON.stringify(whitelistInfo));
        info[currentTier['tier-id']] += amount * tokenPerFungible;
        dispatch(saleSlice.actions.setWhitelistInfo(info));
      }
    }
  }
}

