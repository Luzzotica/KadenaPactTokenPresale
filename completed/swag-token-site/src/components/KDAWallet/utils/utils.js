import { listen, send, local } from '@kadena/chainweb-node-client';
import { hash } from '@kadena/cryptography-utils';

/// Pact API Functions

export const creationTime = () => String(Math.round(new Date().getTime() / 1000) - 10);

export const buildUrl = (network, networkId, chainId) => {
  return `${network}/chainweb/0.0/${networkId}/chain/${chainId}/pact`;
}

// export const createPactCommandPayload = (getState, chainId, pactCode, envData={}, gasLimit=15000, gasPrice=1e-5, caps=[]) => {
//   let kadenaSliceState = getState().kadenaInfo;
//   let publicKey = kadenaSliceState.pubKey;

//   return {
//     networkId: kadenaSliceState.networkId,
//     payload: {
//       exec: {
//         data: envData,
//         code: pactCode,
//       }
//     },
//     signers: [{
//       pubKey: publicKey,
//       clist: caps,
//     }], // [signer]
//     meta: {
//       chainId: chainId,
//       gasLimit: gasLimit,
//       gasPrice: gasPrice,
//       sender: kadenaSliceState.account,
//       ttl: kadenaSliceState.ttl,
//       creationTime: creationTime(),
//     },
//     nonce: Date.now().toString(),
//   };
// }

export const createReadonlyPactCommand = (getState, chainId, pactCode, envData={}, gasLimit=15000, gasPrice=1e-5) => {
  let kadenaSliceState = getState().kadenaInfo;

  let cmd = {
    networkId: kadenaSliceState.networkId,
    payload: {
      exec: {
        data: envData,
        code: pactCode,
      }
    },
    signers: [], // [signer]
    meta: {
      chainId: chainId,
      gasLimit: gasLimit,
      gasPrice: gasPrice,
      sender: kadenaSliceState.account,
      ttl: kadenaSliceState.ttl,
      creationTime: creationTime(),
    },
    nonce: Date.now().toString(),
  };
  let cmdString = JSON.stringify(cmd);
  let h = hash(cmdString);

  return {
    cmd: cmdString,
    hash: h,
    sigs: [],
  }
}

/// Wallet Signing Functions 

export const createDappCap = (role, description, name, args) => {
  return {
    role: role,
    description: description,
    cap: {
      name: name,
      args: args,
    }
  }
}

export const createSigningRequest = (getState, chainId, pactCode, envData, dappCaps=[], gasLimit=15000, gasPrice=1e-5) => {
  let kadenaSliceState = getState().kadenaInfo;
  return {
    pactCode: pactCode,
    envData: envData,
    sender: kadenaSliceState.account,
    networkId: kadenaSliceState.networkId,
    chainId: chainId,
    gasLimit: gasLimit,
    gasPrice: gasPrice,
    signingPubKey: kadenaSliceState.pubKey,
    ttl: kadenaSliceState.ttl,
    caps: dappCaps,
  }
}

export const localCommand = async function (getState, chainId, cmd) {
  let kadenaInfo = getState().kadenaInfo;
  let networkUrl = buildUrl(kadenaInfo.network, kadenaInfo.networkId, chainId);

  return await local(cmd, networkUrl);
}

export const sendCommand = async function(getState, chainId, signedCmd) {
  let kadenaInfo = getState().kadenaInfo;
  let networkUrl = buildUrl(kadenaInfo.network, kadenaInfo.networkId, chainId);

  return await send({ cmds: [signedCmd] }, networkUrl);
}

export const listenTx = async function (getState, chainId, txId) {
  let kadenaInfo = getState().kadenaInfo;
  let networkUrl = buildUrl(kadenaInfo.network, kadenaInfo.networkId, chainId);
  return await listen({ listen: txId }, networkUrl);
}