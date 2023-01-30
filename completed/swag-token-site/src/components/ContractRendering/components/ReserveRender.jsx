import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CustomButton from '../../Layout/CustomButton';
import FlexColumn from '../../Layout/FlexColumn';
import FlexRow from '../../Layout/FlexRow';
import { reserveTokens } from '../store/saleSlice';

function ReserveRender() {
  const chainId = import.meta.env.VITE_CHAIN_ID;
  const tokenName = import.meta.env.VITE_TOKEN_NAME;

  const dispatch = useDispatch();

  const account = useSelector(state => state.kadenaInfo.account);
  const whitelistInfo = useSelector(state => state.saleInfo.whitelistInfo);
  const currentTier = useSelector(state => state.saleInfo.currentTier);
  const [tokenPerFungible, setTokenPerFungible] = useState(-1);
  const [purchaseAmount, setPurchaseAmount] = useState(-1);
  const [tokenMin, setTokenMin] = useState(-1);
  const [tokenMax, setTokenMax] = useState(-1);
  const [remainingPurchase, setRemainingPurchase] = useState(-1);
  useEffect(() => {
    if (Object.keys(currentTier).length === 0) {
      return;
    }
    // console.log(currentTier);

    // If the tier type is WL
    if ('tier-type' in currentTier 
      && currentTier['tier-type'] === 'WL') {
      // console.log('current tier: ', currentTier);
      // console.log('whitelist info: ', whitelistInfo);

      // Whitelisted if the tier is our whitelist 
      // and the whitelist purchase amount is not -1
      if (currentTier['tier-id'] in whitelistInfo
        && whitelistInfo[currentTier['tier-id']] >= 0) {
        setPurchaseAmount(whitelistInfo[currentTier['tier-id']]);
        setTokenMin(currentTier['min-token']);
        setTokenMax(currentTier['max-token']);
        setTokenPerFungible(currentTier['token-per-fungible']);
      }
      else { // If we aren't whitelisted, set the price to -1
        setPurchaseAmount(-1);
        setTokenMin(-1);
        setTokenMax(-1);
        setTokenPerFungible(-1);
      }
    }
    else {
      setPurchaseAmount(-1);
      setTokenMin(currentTier['min-token']);
      setTokenMax(currentTier['max-token']);
      setTokenPerFungible(currentTier['token-per-fungible']);
    }
    
  }, [currentTier, whitelistInfo]);

  useEffect(() => {
    if (purchaseAmount === -1 || tokenMin === -1) {
      setRemainingPurchase(-1);
    }
    setRemainingPurchase(tokenMin - purchaseAmount);
  }, [purchaseAmount, tokenMin]);

  const [purchaseInfo, setPurchaseInfo] = useState('');
  useEffect(() => {
    // If the min and max are -1, don't show anything
    if (tokenMin === -1 && tokenMax === -1) {
      setPurchaseInfo('');
    }
    // If both min and max exist, say what they are
    else if (tokenMin !== -1 && tokenMax !== -1) {
      setPurchaseInfo(`Must purchase between ${tokenMin} and ${tokenMax} ${tokenName}`);
    }
    // If the min exists, say what it is
    else if (tokenMin !== -1) {
      setPurchaseInfo(`Must purchase at least ${tokenMin} ${tokenName}`);
    }
    // If the max exists, say what it is
    else if (tokenMax !== -1) {
      setPurchaseInfo(`Must purchase less than ${tokenMax} ${tokenName}`);
    }
  }, [tokenMin, tokenMax]);

  const [amount, setAmount] = useState(0.1);
  const [amountToken, setAmountToken] = useState(0.1);
  useEffect(() => {
    setAmountToken(amount * tokenPerFungible);
  }, [amount, tokenPerFungible]);

  const [canReserve, setCanReserve] = useState(false);
  const [cantReserveReason, setCantReserveReason] = useState('');
  useEffect(() => {
    // If the amount is outside of the bounds set, stop it
    if (tokenMin !== -1 && tokenMin > amountToken) {
      setCanReserve(false);
      setCantReserveReason(`Must purchase at least ${tokenMin} ${tokenName}`);
    }
    else if (tokenMax !== -1 && tokenMax < amountToken) {
      setCanReserve(false);
      setCantReserveReason(`Must purchase less than ${tokenMax} ${tokenName}`);
    }
    else {
      setCanReserve(true);
      setCantReserveReason('');
    }
  }, [amount, tokenMin, tokenMax, amountToken]);

  const onInputChanged = (e) => {
    let id = e.target.id;
    if (id === 'amount') {
      let amount = Number(e.target.value);
      setAmount(amount);
    }
  }

  const reserve = () => {
    dispatch(reserveTokens(chainId, account, amount));
  }

  return (
    <div className="flex flex-row gap-2 justify-center place-items-center">
      <FlexColumn className="w-96 gap-4 justify-center place-items-center">
        {tokenPerFungible >= 0 && purchaseAmount !== -1 ? 
          <FlexColumn className="flex-auto gap-4 text-center content-center">
            <p className='text-xl'>
              {remainingPurchase === 0 ? 
                "Can't reserve more from this tier!"
              :
                `You can purchase tokens from this tier. ${remainingPurchase}${remainingPurchase === 1.0 ? ' time' : ' times'}`
              }
            </p>
          </FlexColumn>
        :
          <></>
        }
        {tokenPerFungible >= 0 || (currentTier['tier-type'] === 'WL' && remainingPurchase > 0) ? 
          <FlexColumn className="flex-auto w-80 gap-4 place-items-stretch">
            {purchaseInfo !== '' ? 
              <p className='text-xl text-center'>{purchaseInfo}</p>
              :
              <></>
            }
            <FlexRow className="flex-1 gap-2 place-items-stretch">
              <input 
                id="amount"
                type="number"
                value={amount}
                onChange={onInputChanged}
                className='flex-auto bg-slate-800 rounded-md p-1 text-center'>
              </input>
            </FlexRow>
            <CustomButton
              disabled={!canReserve}
              className='flex-auto'
              text={canReserve ? `Purchase ${amountToken} ${tokenName}` : cantReserveReason}
              onClick={reserve}/>
          </FlexColumn>
        : 
          <></>
        }
      </FlexColumn>
    </div>
  )
}

export default ReserveRender;
