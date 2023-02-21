import { createSlice } from '@reduxjs/toolkit';
import { EVENT_NEW_MSG, EVENT_NEW_TX, EVENT_WALLET_CONNECT } from '../constants/constants';
import providers from '../providers/providers';
import { tryLoadLocal, trySaveLocal } from '../utils/store';
import { createReadonlyPactCommand, createSigningRequest, listenTx, localCommand, sendCommand } from '../utils/utils';
import { hideConnectWalletModal } from './connectWalletModalSlice';

const KADENA_STORE_ACCOUNT_KEY = 'KADENA_STORE_ACCOUNT_KEY';
const KADENA_STORE_PUBKEY_KEY = 'KADENA_STORE_PUBKEY_KEY';
const KADENA_STORE_PROVIDER_KEY = 'KADENA_STORE_PROVIDER_KEY';
var loadedProvider = tryLoadLocal(KADENA_STORE_PROVIDER_KEY);
var loadedAccount = tryLoadLocal(KADENA_STORE_ACCOUNT_KEY);
var loadedPubKey = tryLoadLocal(KADENA_STORE_PUBKEY_KEY);
if (loadedProvider === null) { loadedProvider = ''; }
if (loadedAccount === null) { loadedAccount = ''; }
if (loadedPubKey === null) { loadedPubKey = ''; }

export const kadenaSlice = createSlice({
  name: 'kadenaInfo',
  initialState: {
    network: import.meta.env.VITE_NETWORK,
    networkId: import.meta.env.VITE_NETWORK_ID,
    ttl: 600,
    provider: loadedProvider,
    account: loadedAccount,
    pubKey: loadedPubKey,
    transactions: [],
    newTransaction: {},
    messages: [],
    newMessage: {},
  },
  reducers: {
    setNetwork: (state, action) => {
      state.network = action.payload;
    },
    setNetworkId: (state, action) => {
      state.networkId = action.payload;
    },
    setProvider: (state, action) => {
      state.provider = action.payload;
    },
    setAccount: (state, action) => {
      state.account = action.payload;
    },
    setPubKey: (state, action) => {
      state.pubKey = action.payload;
    },
    setTransactions: (state, action) => {
      state.transactions = action.payload;
    },
    addTransaction: (state, action) => {
      state.transactions.push(action.payload);
      state.newTransaction = action.payload;
    },
    setNewTransaction: (state, action) => {
      state.newTransaction = action.payload;
    },
    addMessage: (state, action) => {
      state.messages.push(action.payload);
      state.newMessage = action.payload;
    },
    setNewMessage: (state, action) => {
      state.newMessage = action.payload;
    },
  },
})

export const { 
  setNetwork, setNetworkId, setAccount, setPubKey, 
  addTransaction, setNewTransaction, addMessage, setNewMessage
} = kadenaSlice.actions;

export default kadenaSlice.reducer;


export const connectWithProvider = (providerId) => {
  return async function(dispatch, getState) {
    // Wallet Integration and Signing: Wallet Connection and Disconnection
  }
}

export const disconnectProvider = () => {
  return async function(dispatch, getState) {
    // Wallet Integration and Signing: Wallet Connection and Disconnection
  }
}

export const local = (chainId, pactCode, envData, 
  gasLimit=15000, gasPrice=1e-5) => {
  return async function(dispatch, getState) {
    // Kadena Communication: Local Endpoint
  }
}

export const localAndSend = (chainId, pactCode, envData, 
  caps=[], gasLimit=75000, gasPrice=1e-8) => {
  return async function sign(dispatch, getState) {
    // Wallet Integration and Signing: Wallet Signing
  };
}