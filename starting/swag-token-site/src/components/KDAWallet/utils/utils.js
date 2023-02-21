import { listen, send, local } from '@kadena/chainweb-node-client';
import { hash } from '@kadena/cryptography-utils';

/// Pact API Functions

export const creationTime = () => String(Math.round(new Date().getTime() / 1000) - 10);

export const buildUrl = (network, networkId, chainId) => {
  return `${network}/chainweb/0.0/${networkId}/chain/${chainId}/pact`;
}

export const createReadonlyPactCommand = (getState, chainId, pactCode, envData={}, gasLimit=15000, gasPrice=1e-5) => {
  // Kadena Communication: Supporting Functions
}

export const localCommand = async function (getState, chainId, cmd) {
  // Kadena Communication: Supporting Functions
}

export const sendCommand = async function(getState, chainId, signedCmd) {
  // Kadena Communication: Supporting Functions
}

export const listenTx = async function (getState, chainId, txId) {
  // Kadena Communication: Supporting Functions
}

/// Wallet Signing Functions 

export const createDappCap = (role, description, name, args) => {
  // Wallet Integration and Signing: Supporting Functions
}

export const createSigningRequest = (getState, chainId, pactCode, envData, dappCaps=[], gasLimit=15000, gasPrice=1e-5) => {
  // Wallet Integration and Signing: Supporting Functions
}