import { createSlice } from '@reduxjs/toolkit'
import { local, localAndSend } from '../../KDAWallet/store/kadenaSlice';
import { createDappCap } from '../../KDAWallet/utils/utils';
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
    // Kadena Communication: Fetching Smart Contract Data
  }
}

export const initAccountData = (chainId, account) => {
  return async function(dispatch, getState) {
    // Wallet Integration and Signing: Init Account Data
  }
}

export const reserveTokens = (chainId, account, amount) => {
  return async function(dispatch, getState) {
    // Wallet Integration and Signing: Reserve
  }
}

