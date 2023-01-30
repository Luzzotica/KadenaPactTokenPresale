
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import ConnectWalletModal from '../KDAWallet/components/ConnectWalletModal';
import KadenaEventListener from '../KDAWallet/components/KadenaEventListener';
import { showConnectWalletModal } from '../KDAWallet/store/connectWalletModalSlice';
import { disconnectProvider } from '../KDAWallet/store/kadenaSlice';
import reduceToken from '../KDAWallet/utils/reduceToken';
import CustomButton from '../Layout/CustomButton';
import FlexColumn from '../Layout/FlexColumn';
import FlexRow from '../Layout/FlexRow';
import { messageToastManager, txToastManager, walletConnectedToastManager } from '../TxToast/TxToastManager';
import ContractRender from './components/ContractRender';
import ReserveRender from './components/ReserveRender';
import ReservationRender from './components/ReservationRender';
import { initAccountData, initContractData } from './store/saleSlice';

import './index.css'

function TokenSalePage() {
  const chainId = import.meta.env.VITE_CHAIN_ID

  const dispatch = useDispatch();
  const account = useSelector(state => state.kadenaInfo.account);
  const bank = useSelector(state => state.saleInfo.bank);

  const initData = async () => { 
    await dispatch(initContractData(chainId));
  }

  useEffect(() => {
    initData();
  }, []);

  const initAccount = async () => {
    await dispatch(initAccountData(chainId, account));
  }

  useEffect(() => {
    if (account !== '' && bank !== '') {
      initAccount();
    }
  }, [account, bank]);

  const openModal = () => {
    dispatch(showConnectWalletModal());
  }

  const disconnect = () => {
    dispatch(disconnectProvider());
  } 

  return (
    <div className='h-auto'>
      <ToastContainer />
      <KadenaEventListener
        onNewTransaction={txToastManager}
        onNewMessage={messageToastManager}
        onWalletConnected={walletConnectedToastManager}/>
      <ConnectWalletModal
        className="text-white" 
        modalStyle="border-white border rounded-xl py-4 px-8 shadow-lg min-w-max max-w-xl flex flex-col space-y-4 bg-slate-800"
        buttonStyle="bg-blue-500 border-slate-100 border py-2 px-4 rounded-xl hover:bg-blue-700 active:bg-blue-900 focus:bg-blue-600 transition duration-150 ease-out"
      />
      <FlexColumn className='gap-2 fixed px-2 bottom-2 z-10 w-full sm:w-48 place-items-center sm:place-items-start'>
        <div className="w-20 text-center rounded-3xl bg-slate-900 py-1 px-1">
          <span className="text-sm text-white">Chain {chainId}</span>
        </div>
        {account !== '' ? 
          <FlexColumn className='w-max sm:w-auto gap-1 rounded-3xl bg-slate-900 py-2 px-2'>
            <CustomButton
              className='text-white'
              text={"Disconnect"}
              onClick={disconnect} /> 
            <p className='flex-1 text-center text-white'>{reduceToken(account)}</p>
          </FlexColumn>
          : 
          <></>
        }
      </FlexColumn>
      <div className='hero bg-zinc-800 bg-hero bg-cover bg-left bg-no-repeat text-white py-10'>
        <FlexColumn className='gap-10'>
          <FlexColumn className='gap-10 bg-opacity-50 bg-black rounded-3xl p-4 m-4'>
            <ContractRender/>
            {account === '' ? 
              <div className='flex flex-col place-items-center'>
                <CustomButton
                  className='w-64'
                  text={"Connect Wallet"}
                  onClick={openModal} /> 
              </div>
            : 
              <ReserveRender/>
            }
          </FlexColumn>
        </FlexColumn>
      </div>
      <div className='h-auto w-full'>
        <img 
          src='/spaceman.png'
          className='sticky spin -z-10 w-64 py-10 px-10'
        />
        <img 
          src='/lightsaber.png'
          className='sticky spin -z-10 w-96 px-32'
        />
        <ReservationRender className='z-50 -mt-60 pb-40'/>
      </div>
    </div>
  )
}

export default TokenSalePage